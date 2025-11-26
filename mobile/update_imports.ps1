$replacements = @{
    "package:mobile/screens/courier_dashboard_screen.dart" = "package:mobile/screens/courier/courier_dashboard_screen.dart"
    "package:mobile/screens/courier_login_screen.dart" = "package:mobile/screens/courier/courier_login_screen.dart"
    "package:mobile/screens/vendor_dashboard_screen.dart" = "package:mobile/screens/vendor/vendor_dashboard_screen.dart"
    "package:mobile/screens/vendor_login_screen.dart" = "package:mobile/screens/vendor/vendor_login_screen.dart"
    "package:mobile/screens/vendor_orders_screen.dart" = "package:mobile/screens/vendor/vendor_orders_screen.dart"
    "package:mobile/screens/vendor_order_detail_screen.dart" = "package:mobile/screens/vendor/vendor_order_detail_screen.dart"
    "package:mobile/screens/vendor_reports_screen.dart" = "package:mobile/screens/vendor/vendor_reports_screen.dart"
    "package:mobile/screens/vendor_reviews_screen.dart" = "package:mobile/screens/vendor/vendor_reviews_screen.dart"
    "package:mobile/screens/vendor_review_detail_screen.dart" = "package:mobile/screens/vendor/vendor_review_detail_screen.dart"
    "package:mobile/screens/cart_screen.dart" = "package:mobile/screens/customer/cart_screen.dart"
    "package:mobile/screens/delivery_tracking_screen.dart" = "package:mobile/screens/customer/delivery_tracking_screen.dart"
    "package:mobile/screens/favorites_screen.dart" = "package:mobile/screens/customer/favorites_screen.dart"
    "package:mobile/screens/order_detail_screen.dart" = "package:mobile/screens/customer/order_detail_screen.dart"
    "package:mobile/screens/order_history_screen.dart" = "package:mobile/screens/customer/order_history_screen.dart"
    "package:mobile/screens/product_detail_screen.dart" = "package:mobile/screens/customer/product_detail_screen.dart"
    "package:mobile/screens/product_list_screen.dart" = "package:mobile/screens/customer/product_list_screen.dart"
    "package:mobile/screens/search_screen.dart" = "package:mobile/screens/customer/search_screen.dart"
    "package:mobile/screens/vendor_list_screen.dart" = "package:mobile/screens/customer/vendor_list_screen.dart"
    "package:mobile/screens/vendors_map_screen.dart" = "package:mobile/screens/customer/vendors_map_screen.dart"
    "package:mobile/screens/login_screen.dart" = "package:mobile/screens/shared/auth/login_screen.dart"
    "package:mobile/screens/register_screen.dart" = "package:mobile/screens/shared/auth/register_screen.dart"
    "package:mobile/screens/forgot_password_screen.dart" = "package:mobile/screens/shared/auth/forgot_password_screen.dart"
    "package:mobile/screens/email_verification_screen.dart" = "package:mobile/screens/shared/auth/email_verification_screen.dart"
    "package:mobile/screens/profile_screen.dart" = "package:mobile/screens/shared/profile/profile_screen.dart"
    "package:mobile/screens/edit_profile_screen.dart" = "package:mobile/screens/shared/profile/edit_profile_screen.dart"
    "package:mobile/screens/change_password_screen.dart" = "package:mobile/screens/shared/profile/change_password_screen.dart"
    "package:mobile/screens/addresses_screen.dart" = "package:mobile/screens/shared/profile/addresses_screen.dart"
    "package:mobile/screens/add_edit_address_screen.dart" = "package:mobile/screens/shared/profile/add_edit_address_screen.dart"
    "package:mobile/screens/address_picker_screen.dart" = "package:mobile/screens/shared/profile/address_picker_screen.dart"
    "package:mobile/screens/notification_settings_screen.dart" = "package:mobile/screens/shared/settings/notification_settings_screen.dart"
    "package:mobile/screens/language_settings_screen.dart" = "package:mobile/screens/shared/settings/language_settings_screen.dart"
    "package:mobile/screens/regional_settings_screen.dart" = "package:mobile/screens/shared/settings/regional_settings_screen.dart"
    "package:mobile/screens/currency_settings_screen.dart" = "package:mobile/screens/shared/settings/currency_settings_screen.dart"
    "package:mobile/screens/accessibility_settings_screen.dart" = "package:mobile/screens/shared/settings/accessibility_settings_screen.dart"
    "package:mobile/screens/onboarding_screen.dart" = "package:mobile/screens/shared/onboarding/onboarding_screen.dart"
    "package:mobile/screens/language_selection_screen.dart" = "package:mobile/screens/shared/onboarding/language_selection_screen.dart"
    "package:mobile/screens/main_navigation_screen.dart" = "package:mobile/screens/shared/onboarding/main_navigation_screen.dart"
}

$updatedCount = 0
Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw -Encoding UTF8
    $originalContent = $content
    
    foreach ($old in $replacements.Keys) {
        $new = $replacements[$old]
        $content = $content.Replace($old, $new)
    }
    
    if ($content -ne $originalContent) {
        Set-Content -Path $_.FullName -Value $content -Encoding UTF8 -NoNewline
        Write-Host "Updated: $($_.FullName)"
        $updatedCount++
    }
}

Write-Host "`nTotal files updated: $updatedCount"
