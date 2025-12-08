-- Remove Courier-related fields from Orders table
-- These fields have been moved to OrderCouriers table

-- Step 1: Drop foreign key constraint if exists
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Orders_Couriers_CourierId')
BEGIN
    ALTER TABLE [Orders] DROP CONSTRAINT [FK_Orders_Couriers_CourierId];
    PRINT 'Foreign key constraint FK_Orders_Couriers_CourierId dropped.';
END
GO

-- Step 2: Drop index before dropping the column
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Orders_CourierId' AND object_id = OBJECT_ID('Orders'))
BEGIN
    DROP INDEX [IX_Orders_CourierId] ON [Orders];
    PRINT 'Index IX_Orders_CourierId dropped.';
END
GO

-- Step 3: Drop columns
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Orders') AND name = 'CourierId')
BEGIN
    ALTER TABLE [Orders] DROP COLUMN [CourierId];
    PRINT 'Column CourierId dropped.';
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Orders') AND name = 'CourierAssignedAt')
BEGIN
    ALTER TABLE [Orders] DROP COLUMN [CourierAssignedAt];
    PRINT 'Column CourierAssignedAt dropped.';
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Orders') AND name = 'CourierAcceptedAt')
BEGIN
    ALTER TABLE [Orders] DROP COLUMN [CourierAcceptedAt];
    PRINT 'Column CourierAcceptedAt dropped.';
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Orders') AND name = 'PickedUpAt')
BEGIN
    ALTER TABLE [Orders] DROP COLUMN [PickedUpAt];
    PRINT 'Column PickedUpAt dropped.';
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Orders') AND name = 'OutForDeliveryAt')
BEGIN
    ALTER TABLE [Orders] DROP COLUMN [OutForDeliveryAt];
    PRINT 'Column OutForDeliveryAt dropped.';
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Orders') AND name = 'DeliveredAt')
BEGIN
    ALTER TABLE [Orders] DROP COLUMN [DeliveredAt];
    PRINT 'Column DeliveredAt dropped.';
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Orders') AND name = 'CourierTip')
BEGIN
    ALTER TABLE [Orders] DROP COLUMN [CourierTip];
    PRINT 'Column CourierTip dropped.';
END
GO

PRINT 'All courier-related fields have been removed from Orders table successfully!';
PRINT 'Note: DeliveryFee column is kept in Orders table as it represents customer fee.';
PRINT 'Courier payment information is now stored in OrderCouriers table.';
GO

