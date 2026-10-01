# Synthetic ERP Domain Model

## Core Entities & Relationships

The synthetic `ApexOperations ERP` domain covers the complete lifecycle from commercial order quotation to manufacturing delivery:

```mermaid
erDiagram
    CUSTOMERS ||--o{ SALES_ORDERS : places
    SALES_ORDERS ||--|{ ORDER_LINES : contains
    ORDER_LINES }o--|| COMPONENTS : references
    SALES_ORDERS ||--o{ PRODUCTION_WORK_ORDERS : triggers
    PRODUCTION_WORK_ORDERS ||--|{ ROUTING_STEPS : executes
    ROUTING_STEPS }o--|| WORKSTATIONS : allocated_to
    COMPONENTS ||--o{ INVENTORY_BIN_STOCK : stored_in
    SUPPLIERS ||--o{ PURCHASE_ORDERS : fulfills
```

## Entity Invariants
1. **SalesOrder:** Cannot transition to `Dispatched` until all associated `ProductionWorkOrders` have status `Completed` and QA sign-off.
2. **InventoryBinStock:** Quantity available = `QuantityOnHand - QuantityAllocated`. Quantity available must never be negative.
3. **RoutingStep:** Steps must execute strictly in ascending `SequenceNumber` order (e.g. 10: Laser Cut -> 20: CNC Bend -> 30: Powder Coat -> 40: Final Assembly).
