-- Migration: AddOrderItemCancellationFields
-- Add cancellation fields to OrderItems table

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[OrderItems]') AND name = 'IsCancelled')
BEGIN
    ALTER TABLE [dbo].[OrderItems]
    ADD [IsCancelled] bit NOT NULL DEFAULT 0;
    PRINT 'IsCancelled column added to OrderItems table';
END
ELSE
BEGIN
    PRINT 'IsCancelled column already exists in OrderItems table';
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[OrderItems]') AND name = 'CancelledAt')
BEGIN
    ALTER TABLE [dbo].[OrderItems]
    ADD [CancelledAt] datetime2 NULL;
    PRINT 'CancelledAt column added to OrderItems table';
END
ELSE
BEGIN
    PRINT 'CancelledAt column already exists in OrderItems table';
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[OrderItems]') AND name = 'CancelReason')
BEGIN
    ALTER TABLE [dbo].[OrderItems]
    ADD [CancelReason] nvarchar(max) NULL;
    PRINT 'CancelReason column added to OrderItems table';
END
ELSE
BEGIN
    PRINT 'CancelReason column already exists in OrderItems table';
END
GO

-- Insert migration record if not exists
IF NOT EXISTS (SELECT * FROM [__EFMigrationsHistory] WHERE [MigrationId] = '20251202011328_AddOrderItemCancellationFields')
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES ('20251202011328_AddOrderItemCancellationFields', '9.0.0');
    PRINT 'Migration record added to __EFMigrationsHistory';
END
ELSE
BEGIN
    PRINT 'Migration record already exists in __EFMigrationsHistory';
END
GO

PRINT 'Migration completed successfully!';
GO

