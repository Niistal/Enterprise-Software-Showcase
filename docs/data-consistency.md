# Data Consistency, Transactions & Stored Procedure Standards

## SQL Server Transactional Guarantees

In manufacturing ERP systems, data corruption during stock transfers or partial invoicing cannot be tolerated.

### 1. Isolation Levels
- Enable **Read Committed Snapshot Isolation (`RCSI`)** on the database level:
  ```sql
  ALTER DATABASE ApexOperationsDb SET READ_COMMITTED_SNAPSHOT ON;
  ```
  *Benefit:* Readers do not block writers, and writers do not block readers, drastically reducing lock contention across hundreds of warehouse terminals.

### 2. Standardized Stored Procedure Template
Every transactional procedure enforces explicit transaction boundaries, error handling, and structured logging:

```sql
CREATE OR ALTER PROCEDURE dbo.usp_ProcessOrderAllocation
    @OrderId INT,
    @AllocatedByUserId INT,
    @AllocatedLineCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- Automatically rollback on runtime error

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Validate order state with pessimistic lock
        DECLARE @CurrentStatus VARCHAR(20);
        SELECT @CurrentStatus = Status
        FROM dbo.SalesOrders WITH (UPDLOCK, HOLDLOCK)
        WHERE OrderId = @OrderId;

        IF @CurrentStatus <> 'Approved'
            THROW 50001, 'Order must be in Approved state before allocation.', 1;

        -- 2. Allocate inventory lines atomically
        UPDATE inv
        SET inv.QuantityAllocated = inv.QuantityAllocated + lines.QuantityRequired,
            inv.ModifiedUtc = SYSUTCDATETIME()
        FROM dbo.InventoryBinStock inv
        INNER JOIN dbo.SalesOrderLines lines ON inv.ComponentId = lines.ComponentId
        WHERE lines.OrderId = @OrderId;

        -- 3. Transition order status
        UPDATE dbo.SalesOrders
        SET Status = 'Allocated',
            AllocatedUtc = SYSUTCDATETIME()
        WHERE OrderId = @OrderId;

        -- 4. Record audit ledger entry
        INSERT INTO dbo.AuditEventLog (EntityName, EntityId, ActionType, UserId, TimestampUtc)
        VALUES ('SalesOrders', @OrderId, 'ALLOCATED', @AllocatedByUserId, SYSUTCDATETIME());

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
```
