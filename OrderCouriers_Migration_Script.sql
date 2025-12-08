-- OrderCouriers Table Migration Script
-- This script creates the OrderCouriers table and migrates existing data

-- Step 1: Create OrderCouriers table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'OrderCouriers')
BEGIN
    CREATE TABLE [dbo].[OrderCouriers] (
        [Id] uniqueidentifier NOT NULL,
        [OrderId] uniqueidentifier NOT NULL,
        [CourierId] uniqueidentifier NOT NULL,
        [CourierAssignedAt] datetime2 NULL,
        [CourierAcceptedAt] datetime2 NULL,
        [CourierRejectedAt] datetime2 NULL,
        [RejectReason] nvarchar(max) NULL,
        [PickedUpAt] datetime2 NULL,
        [OutForDeliveryAt] datetime2 NULL,
        [DeliveredAt] datetime2 NULL,
        [DeliveryFee] decimal(18,2) NOT NULL DEFAULT 0,
        [CourierTip] decimal(18,2) NULL,
        [IsActive] bit NOT NULL DEFAULT 1,
        [Status] int NOT NULL DEFAULT 0,
        [CreatedAt] datetime2 NOT NULL,
        [UpdatedAt] datetime2 NULL,
        CONSTRAINT [PK_OrderCouriers] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_OrderCouriers_Orders_OrderId] FOREIGN KEY ([OrderId]) REFERENCES [Orders] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_OrderCouriers_Couriers_CourierId] FOREIGN KEY ([CourierId]) REFERENCES [Couriers] ([Id]) ON DELETE NO ACTION
    );
END
GO

-- Step 2: Create indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_OrderCouriers_OrderId')
BEGIN
    CREATE INDEX [IX_OrderCouriers_OrderId] ON [OrderCouriers] ([OrderId]);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_OrderCouriers_CourierId')
BEGIN
    CREATE INDEX [IX_OrderCouriers_CourierId] ON [OrderCouriers] ([CourierId]);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_OrderCouriers_OrderId_IsActive')
BEGIN
    CREATE INDEX [IX_OrderCouriers_OrderId_IsActive] ON [OrderCouriers] ([OrderId], [IsActive]) WHERE [IsActive] = 1;
END
GO

-- Step 3: Migrate existing data from Orders to OrderCouriers
-- Only migrate if there's data and it hasn't been migrated yet
IF NOT EXISTS (SELECT TOP 1 1 FROM [OrderCouriers])
BEGIN
    INSERT INTO [OrderCouriers] (
        [Id], [OrderId], [CourierId],
        [CourierAssignedAt], [CourierAcceptedAt], [PickedUpAt], 
        [OutForDeliveryAt], [DeliveredAt],
        [DeliveryFee], [CourierTip],
        [IsActive], [Status], [CreatedAt], [UpdatedAt]
    )
    SELECT 
        NEWID() AS [Id],
        [Id] AS [OrderId],
        [CourierId],
        [CourierAssignedAt],
        [CourierAcceptedAt],
        [PickedUpAt],
        [OutForDeliveryAt],
        [DeliveredAt],
        [DeliveryFee],
        [CourierTip],
        1 AS [IsActive],
        CASE 
            WHEN [DeliveredAt] IS NOT NULL THEN 5
            WHEN [OutForDeliveryAt] IS NOT NULL THEN 4
            WHEN [PickedUpAt] IS NOT NULL THEN 3
            WHEN [CourierAcceptedAt] IS NOT NULL THEN 1
            WHEN [CourierAssignedAt] IS NOT NULL THEN 0
            ELSE 0
        END AS [Status],
        [CreatedAt],
        [UpdatedAt]
    FROM [Orders]
    WHERE [CourierId] IS NOT NULL;
    
    PRINT 'Data migration completed. ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' records migrated.';
END
ELSE
BEGIN
    PRINT 'OrderCouriers table already contains data. Skipping data migration.';
END
GO

PRINT 'OrderCouriers table migration completed successfully!';
GO

