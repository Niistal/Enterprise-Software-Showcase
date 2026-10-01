# Legacy Modernization Guide (.NET Framework to .NET 8)

## The Incremental Modernization Philosophy

Enterprise systems cannot afford long maintenance freezes. The following 4-phase methodology guarantees continuous system availability during modernization:

### Phase 1: Dependency & Target Audit
- Audit all `.csproj` and `.vbproj` files using the .NET Upgrade Assistant.
- Identify blocking third-party ActiveX controls, legacy COM dependencies, and direct GDI+ calls.
- Pin target frameworks: Multi-target shared libraries to `netstandard2.0` and `net8.0-windows`.

### Phase 2: Decoupling UI from Business Logic
- Extract SQL queries from WinForms form code-behinds (`Form.vb` / `Form.cs`).
- Introduce the **Model-View-Presenter (MVP)** or **MVVM** pattern into Windows Forms to decouple data binding from window rendering.
- Replace untyped `DataSet` and `DataTable` collections with strongly typed C# record DTOs.

### Phase 3: Transitioning ODBC to Parameterized Stored Procedures
- Legacy code frequently uses direct ODBC string concatenation (high SQL injection risk and sub-optimal query plans).
- Standardize all queries into T-SQL stored procedures called via `Microsoft.Data.SqlClient` or ADO.NET with explicit parameter types (`SqlDbType.Int`, `SqlDbType.NVarChar`).

### Phase 4: Modern Web Gateway (.NET 8 ASP.NET Core)
- Stand up an ASP.NET Core Web API alongside legacy services.
- Leverage modern C# 12 features (primary constructors, pattern matching, collections expressions) for high developer velocity.
- Secure API endpoints using JWT authentication and role-based authorization matching existing enterprise active directory groups.
