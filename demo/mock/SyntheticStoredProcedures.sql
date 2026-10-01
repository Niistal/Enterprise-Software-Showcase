-- ============================================================================
-- ApexOperations ERP - Synthetic Stored Procedures Demo
-- Demonstrates enterprise transaction management, table-valued parameters,
-- and deadlock-free locking patterns in SQL Server 2022.
-- ============================================================================

CREATE TYPE dbo.OrderLineTableType AS TABLE
(
    ComponentId INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18, 4) NOT NULL
);
GO

CREATE OR ALTER PROCEDURE dbo.usp_CreateSalesOrderWithLines
    @CustomerId INT,
    @DeliveryAddress NVARCHAR(250),
    @CreatedByUserId INT,
    @Lines dbo.OrderLineTableType READONLY,
    @GeneratedOrderId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Validate Customer Status
        IF NOT EXISTS (SELECT 1 FROM dbo.Customers WHERE CustomerId = @CustomerId AND IsActive = 1)
        BEGIN
            THROW 50010, 'Invalid or inactive customer ID.', 1;
        END

        -- 2. Insert Order Header
        INSERT INTO dbo.SalesOrders (CustomerId, DeliveryAddress, Status, CreatedByUserId, CreatedUtc)
        VALUES (@CustomerId, @DeliveryAddress, 'Draft', @CreatedByUserId, SYSUTCDATETIME());

        SET @GeneratedOrderId = SCOPE_IDENTITY();

        -- 3. Batch Insert Order Lines from TVP
        INSERT INTO dbo.SalesOrderLines (OrderId, ComponentId, Quantity, UnitPrice, LineTotal)
        SELECT 
            @GeneratedOrderId,
            l.ComponentId,
            l.Quantity,
            l.UnitPrice,
            (l.Quantity * l.UnitPrice)
        FROM @Lines l;

        -- 4. Record Audit Event
        INSERT INTO dbo.AuditEventLog (EntityName, EntityId, ActionType, UserId, TimestampUtc)
        VALUES ('SalesOrders', @GeneratedOrderId, 'CREATE', @CreatedByUserId, SYSUTCDATETIME());

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
