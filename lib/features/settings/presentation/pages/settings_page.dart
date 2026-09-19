// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/widgets/keyboard_shortcuts_dialog.dart';
import '../widgets/add_location_view.dart';
import '../widgets/api_webhooks_view.dart';
import '../widgets/barcode_printing_view.dart';
import '../widgets/business_profile_view.dart';
import '../widgets/data_retention_view.dart';
import '../widgets/document_settings_view.dart';
import '../widgets/edit_role_view.dart';
import '../widgets/import_export_center_view.dart';
import '../widgets/instore_pos_channel_view.dart';
import '../widgets/integrations_marketplace_view.dart';
import '../widgets/inventory_rules_view.dart';
import '../widgets/locations_view.dart';
import '../widgets/notification_preferences_view.dart';
import '../widgets/purchasing_defaults_view.dart';
import '../widgets/roles_permissions_view.dart';
import '../widgets/sales_channels_view.dart';
import '../widgets/security_authentication_view.dart';
import '../widgets/settings_search_results_view.dart';
import '../widgets/shopify_connector_view.dart';
import '../widgets/system_audit_log_view.dart';
import '../widgets/system_integration_sync_view.dart';
import '../widgets/system_settings_view.dart';
import '../widgets/taxes_currency_view.dart';
import '../widgets/team_access_view.dart';
import '../widgets/transfer_settings_view.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    this.initialSection = 'system_settings',
    this.onSubNavChanged,
  });

  final String initialSection;
  final void Function(String title, String subtitle)? onSubNavChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String _currentSection;
  int _selectedNavIndex = 0;

  // Preferences: Appearance & Localization
  String _visualTheme = 'Light Theme';
  String _primaryLanguage = 'English (Global US)';
  String _dateFormat = 'DD/MM/YYYY';
  String _firstDayOfWeek = 'Monday';

  // Preferences: Operational Defaults
  String _defaultLandingDashboard = 'Central Warehouse (Zone A)';
  bool _enableGuidedOnboarding = true;
  String _tableDensity = 'Compact Density';
  String _defaultRowsPerPage = '50 Items';
  bool _enableQuickKeyboardShortcuts = true;

  // Help & Support form state
  final TextEditingController _supportSubjectController = TextEditingController();
  String _selectedSupportCategory = 'Inventory Reconciliation & Auditing';
  final TextEditingController _supportDescController = TextEditingController();

  @override
  void dispose() {
    _supportSubjectController.dispose();
    _supportDescController.dispose();
    super.dispose();
  }

  final List<_SettingsNavItem> _navItems = const [
    _SettingsNavItem(
      label: 'Preferences',
      icon: Icons.grid_view_rounded,
    ),
    _SettingsNavItem(
      label: 'Subscription & Plan',
      icon: Icons.subtitles_outlined,
    ),
    _SettingsNavItem(
      label: 'Billing',
      icon: Icons.receipt_long_outlined,
    ),
    _SettingsNavItem(
      label: 'Help & Support',
      icon: Icons.help_outline_rounded,
    ),
    _SettingsNavItem(
      label: 'System Status',
      icon: Icons.show_chart_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentSection = widget.initialSection;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentSection == 'settings_search' || _currentSection == 'search') {
        widget.onSubNavChanged?.call(
          'Settings Search',
          '',
        );
      } else if (_currentSection == 'system_settings' || _currentSection == 'data_retention') {
        widget.onSubNavChanged?.call(
          'System Settings',
          '',
        );
      } else if (_currentSection == 'add_location') {
        widget.onSubNavChanged?.call(
          'Add Location',
          'Settings → Locations → Add Location',
        );
      } else if (_currentSection == 'locations') {
        widget.onSubNavChanged?.call(
          'Locations',
          'Settings > Locations',
        );
      } else if (_currentSection == 'business_profile') {
        widget.onSubNavChanged?.call(
          'Business Profile',
          'Settings > Business Profile',
        );
      } else if (_currentSection == 'taxes_currency') {
        widget.onSubNavChanged?.call(
          'Taxes & Currency',
          'Manage your default currency, display formats, tax profiles, and calculation rules.',
        );
      } else if (_currentSection == 'documents_templates') {
        widget.onSubNavChanged?.call(
          'Document Settings',
          'Configure document formats, serial numbers, and brand elements for system-generated and external PDFs.',
        );
      } else if (_currentSection == 'team_directory') {
        widget.onSubNavChanged?.call(
          'Team & Access',
          'Manage your team, node allocations, and access permissions.',
        );
      } else if (_currentSection == 'roles_permissions') {
        widget.onSubNavChanged?.call(
          'Roles & Permissions',
          'Manage workspace roles, permissions and granular system capabilities.',
        );
      } else if (_currentSection == 'edit_role') {
        widget.onSubNavChanged?.call(
          'Settings > Roles > Edit Role: Inventory Staff',
          '',
        );
      } else if (_currentSection == 'security_sso' || _currentSection == 'security') {
        widget.onSubNavChanged?.call(
          'Settings > Security',
          'Enforce strong security policies, session handling and review active team session logs.',
        );
      } else if (_currentSection == 'sales_channels') {
        widget.onSubNavChanged?.call(
          'Settings > Sales Channels',
          'Connect, manage and configure active physical or digital checkout points of sale.',
        );
      } else if (_currentSection == 'pos_channel' || _currentSection == 'instore_pos') {
        widget.onSubNavChanged?.call(
          'Settings > Sales Channels > In-Store POS',
          '',
        );
      } else if (_currentSection == 'integrations') {
        widget.onSubNavChanged?.call(
          'Settings > Integrations',
          'Link e-commerce channels, courier aggregators, and enterprise accounting software.',
        );
      } else if (_currentSection == 'shopify_connector' || _currentSection == 'shopify') {
        widget.onSubNavChanged?.call(
          'Integrations > Shopify Connector',
          'Connect your Shopify store to sync products, inventory and orders with ThreadStock.',
        );
      } else if (_currentSection == 'notifications_schema' ||
          _currentSection == 'notification_settings' ||
          _currentSection == 'notifications') {
        widget.onSubNavChanged?.call(
          'Settings > Notification Settings',
          'Choose which alerts you wish to receive across each system channel.',
        );
      } else if (_currentSection == 'barcode_printing' ||
          _currentSection == 'barcode' ||
          _currentSection == 'printing') {
        widget.onSubNavChanged?.call(
          'Settings > Barcode & Printing',
          'Configure barcode settings, manage printers and customize label templates.',
        );
      } else if (_currentSection == 'inventory_rules' ||
          _currentSection == 'rules' ||
          _currentSection == 'stock_rules') {
        widget.onSubNavChanged?.call(
          'Settings > Inventory Rules',
          'Define stock thresholds, reorder logic, and additional inventory rules for your business.',
        );
      } else if (_currentSection == 'purchasing_defaults' ||
          _currentSection == 'purchasing' ||
          _currentSection == 'po_defaults') {
        widget.onSubNavChanged?.call(
          'Settings > Purchasing Defaults > Central Warehouse (Zone A)',
          'Configure buying, receiving and cost settings for your business.',
        );
      } else if (_currentSection == 'transfer_settings' ||
          _currentSection == 'transfer_defaults' ||
          _currentSection == 'transfers_schema') {
        widget.onSubNavChanged?.call(
          'Settings > Transfer Settings > Central Warehouse (Zone A)',
          'Configure stock transfer workflows, transit times and receiving preferences.',
        );
      } else if (_currentSection == 'import_export' ||
          _currentSection == 'import_export_studio' ||
          _currentSection == 'import_export_center') {
        widget.onSubNavChanged?.call(
          'Settings > Import / Export Center > Central Warehouse (Zone A)',
          'Import and export your business data with ease. Manage files, track history, and ensure data accuracy.',
        );
      } else if (_currentSection == 'api_webhooks' ||
          _currentSection == 'webhooks' ||
          _currentSection == 'api') {
        widget.onSubNavChanged?.call(
          'Settings > API & Webhooks > Central Warehouse (Zone A)',
          'Manage API access, configure webhooks, and integrate with external systems.',
        );
      } else if (_currentSection == 'audit_log' ||
          _currentSection == 'system_audit_log' ||
          _currentSection == 'activity_logs') {
        widget.onSubNavChanged?.call(
          'Settings > System Audit Log > Central Warehouse (Zone A)',
          'Track all system changes, user actions, and important events across ThreadStock.',
        );
      } else if (_currentSection == 'sync_queue' ||
          _currentSection == 'system_integration_sync' ||
          _currentSection == 'integration_sync') {
        widget.onSubNavChanged?.call(
          'Sync Queue > System Status > Sync',
          'Monitor real-time data flows between ThreadStock and connected external integrations.',
        );
      } else {
        _notifyNavChanged(0);
      }
    });
  }

  @override
  void didUpdateWidget(SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSection != widget.initialSection) {
      setState(() {
        _currentSection = widget.initialSection;
      });
    }
  }

  void _notifyNavChanged(int index) {
    if (widget.onSubNavChanged == null) return;
    switch (index) {
      case 0:
        widget.onSubNavChanged!(
          'Preferences',
          'Tailor the interface and default configurations for Atelier OS',
        );
        break;
      case 1:
        widget.onSubNavChanged!(
          'Subscription & Plan',
          'Manage billing cycles, system limits, and package upgrades.',
        );
        break;
      case 2:
        widget.onSubNavChanged!(
          'Billing',
          'Manage payment instruments, corporate GSTIN, and past statements.',
        );
        break;
      case 3:
        widget.onSubNavChanged!(
          'Help & Support',
          'Access resources, system guides, or open a ticket directly with technical support.',
        );
        break;
      case 4:
      default:
        widget.onSubNavChanged!(
          'System Status',
          'Live health logs and scheduled database maintenance updates',
        );
        break;
    }
  }

  void _onNavSelected(int index) {
    setState(() => _selectedNavIndex = index);
    _notifyNavChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentSection == 'settings_search' || _currentSection == 'search') {
      return SettingsSearchResultsView(
        searchQuery: 'tax',
        onClearSearch: () {
          setState(() => _currentSection = 'system_settings');
          widget.onSubNavChanged?.call('System Settings', '');
        },
        onBrowseAllSettings: () {
          setState(() => _currentSection = 'system_settings');
          widget.onSubNavChanged?.call('System Settings', '');
        },
        onSelectSection: (sec) {
          setState(() {
            _currentSection = sec;
            if (sec == 'taxes_currency') {
              widget.onSubNavChanged?.call(
                'Taxes & Currency',
                'Manage your default currency, display formats, tax profiles, and calculation rules.',
              );
            } else if (sec == 'locations') {
              widget.onSubNavChanged?.call('Locations', 'Settings > Locations');
            } else if (sec == 'roles_permissions') {
              widget.onSubNavChanged?.call(
                'Roles & Permissions',
                'Manage workspace roles, permissions and granular system capabilities.',
              );
            } else if (sec == 'sales_channels') {
              widget.onSubNavChanged?.call(
                'Settings > Sales Channels',
                'Connect, manage and configure active physical or digital checkout points of sale.',
              );
            } else if (sec == 'general_settings' || sec == 'system_settings') {
              _currentSection = 'system_settings';
              widget.onSubNavChanged?.call('System Settings', '');
            } else if (sec == 'data_retention') {
              widget.onSubNavChanged?.call('System Settings', '');
            } else if (sec == 'integrations') {
              widget.onSubNavChanged?.call(
                'Settings > Integrations',
                'Link e-commerce channels, courier aggregators, and enterprise accounting software.',
              );
            }
          });
        },
      );
    }
    if (_currentSection == 'data_retention') {
      return DataRetentionView(
        onSelectNav: (navId) {
          setState(() {
            _currentSection = navId;
            if (navId == 'general_settings' || navId == 'system_settings') {
              _currentSection = 'system_settings';
              widget.onSubNavChanged?.call('System Settings', '');
            } else if (navId == 'locations') {
              _currentSection = 'locations';
              widget.onSubNavChanged?.call('Locations', 'Settings > Locations');
            } else if (navId == 'roles_permissions') {
              _currentSection = 'roles_permissions';
              widget.onSubNavChanged?.call(
                'Roles & Permissions',
                'Manage workspace roles, permissions and granular system capabilities.',
              );
            } else if (navId == 'integrations') {
              _currentSection = 'integrations';
              widget.onSubNavChanged?.call(
                'Settings > Integrations',
                'Link e-commerce channels, courier aggregators, and enterprise accounting software.',
              );
            } else if (navId == 'data_retention') {
              widget.onSubNavChanged?.call('System Settings', '');
            }
          });
        },
        onBackToSettings: () {
          setState(() => _currentSection = 'system_settings');
          widget.onSubNavChanged?.call('System Settings', '');
        },
      );
    }
    if (_currentSection == 'system_settings') {
      return SystemSettingsView(
        onSelectSection: (section) {
          setState(() {
            _currentSection = section;
            if (section == 'preferences') {
              _selectedNavIndex = 0;
              _notifyNavChanged(0);
            } else if (section == 'subscription') {
              _selectedNavIndex = 1;
              _notifyNavChanged(1);
            } else if (section == 'billing') {
              _selectedNavIndex = 2;
              _notifyNavChanged(2);
            } else if (section == 'help') {
              _selectedNavIndex = 3;
              _notifyNavChanged(3);
            } else if (section == 'business_profile') {
              widget.onSubNavChanged?.call(
                'Business Profile',
                'Settings > Business Profile',
              );
            } else if (section == 'locations') {
              widget.onSubNavChanged?.call(
                'Locations',
                'Settings > Locations',
              );
            } else if (section == 'add_location') {
              widget.onSubNavChanged?.call(
                'Add Location',
                'Settings → Locations → Add Location',
              );
            } else if (section == 'taxes_currency') {
              widget.onSubNavChanged?.call(
                'Taxes & Currency',
                'Manage your default currency, display formats, tax profiles, and calculation rules.',
              );
            } else if (section == 'documents_templates') {
              widget.onSubNavChanged?.call(
                'Document Settings',
                'Configure document formats, serial numbers, and brand elements for system-generated and external PDFs.',
              );
            } else if (section == 'team_directory') {
              widget.onSubNavChanged?.call(
                'Team & Access',
                'Manage your team, node allocations, and access permissions.',
              );
            } else if (section == 'roles_permissions') {
              widget.onSubNavChanged?.call(
                'Roles & Permissions',
                'Manage workspace roles, permissions and granular system capabilities.',
              );
            } else if (section == 'edit_role') {
              widget.onSubNavChanged?.call(
                'Settings > Roles > Edit Role: Inventory Staff',
                '',
              );
            } else if (section == 'security_sso' || section == 'security') {
              widget.onSubNavChanged?.call(
                'Settings > Security',
                'Enforce strong security policies, session handling and review active team session logs.',
              );
            } else if (section == 'sales_channels') {
              widget.onSubNavChanged?.call(
                'Settings > Sales Channels',
                'Connect, manage and configure active physical or digital checkout points of sale.',
              );
            } else if (section == 'integrations') {
              widget.onSubNavChanged?.call(
                'Settings > Integrations',
                'Link e-commerce channels, courier aggregators, and enterprise accounting software.',
              );
            } else if (section == 'notifications_schema' ||
                section == 'notification_settings' ||
                section == 'notifications') {
              widget.onSubNavChanged?.call(
                'Settings > Notification Settings',
                'Choose which alerts you wish to receive across each system channel.',
              );
            } else if (section == 'barcode_printing' ||
                section == 'barcode' ||
                section == 'printing') {
              widget.onSubNavChanged?.call(
                'Settings > Barcode & Printing',
                'Configure barcode settings, manage printers and customize label templates.',
              );
            } else if (section == 'inventory_rules' ||
                section == 'rules' ||
                section == 'stock_rules') {
              widget.onSubNavChanged?.call(
                'Settings > Inventory Rules',
                'Define stock thresholds, reorder logic, and additional inventory rules for your business.',
              );
            } else if (section == 'purchasing_defaults' ||
                section == 'purchasing' ||
                section == 'po_defaults') {
              widget.onSubNavChanged?.call(
                'Settings > Purchasing Defaults > Central Warehouse (Zone A)',
                'Configure buying, receiving and cost settings for your business.',
              );
            } else if (section == 'transfer_settings' ||
                section == 'transfer_defaults' ||
                section == 'transfers_schema') {
              widget.onSubNavChanged?.call(
                'Settings > Transfer Settings > Central Warehouse (Zone A)',
                'Configure stock transfer workflows, transit times and receiving preferences.',
              );
            } else if (section == 'import_export' ||
                section == 'import_export_studio' ||
                section == 'import_export_center') {
              widget.onSubNavChanged?.call(
                'Settings > Import / Export Center > Central Warehouse (Zone A)',
                'Import and export your business data with ease. Manage files, track history, and ensure data accuracy.',
              );
            } else if (section == 'api_webhooks' ||
                section == 'webhooks' ||
                section == 'api') {
              widget.onSubNavChanged?.call(
                'Settings > API & Webhooks > Central Warehouse (Zone A)',
                'Manage API access, configure webhooks, and integrate with external systems.',
              );
            } else if (section == 'audit_log' ||
                section == 'system_audit_log' ||
                section == 'activity_logs') {
              widget.onSubNavChanged?.call(
                'Settings > System Audit Log > Central Warehouse (Zone A)',
                'Track all system changes, user actions, and important events across ThreadStock.',
              );
            } else if (section == 'sync_queue' ||
                section == 'system_integration_sync' ||
                section == 'integration_sync') {
              widget.onSubNavChanged?.call(
                'Sync Queue > System Status > Sync',
                'Monitor real-time data flows between ThreadStock and connected external integrations.',
              );
            }
          });
        },
      );
    }
    if (_currentSection == 'purchasing_defaults' ||
        _currentSection == 'purchasing' ||
        _currentSection == 'po_defaults') {
      return PurchasingDefaultsView(
        onBackToSettings: () {
          setState(() => _currentSection = 'system_settings');
          widget.onSubNavChanged?.call('Settings', '');
        },
        onSubNavChanged: widget.onSubNavChanged,
        onSelectSection: (sec) {
          setState(() {
            _currentSection = sec;
            if (sec == 'transfer_settings' || sec == 'transfer_defaults') {
              widget.onSubNavChanged?.call(
                'Settings > Transfer Settings > Central Warehouse (Zone A)',
                'Configure stock transfer workflows, transit times and receiving preferences.',
              );
            } else if (sec == 'import_export' ||
                sec == 'import_export_studio' ||
                sec == 'import_export_center') {
              widget.onSubNavChanged?.call(
                'Settings > Import / Export Center > Central Warehouse (Zone A)',
                'Import and export your business data with ease. Manage files, track history, and ensure data accuracy.',
              );
            } else if (sec == 'api_webhooks' ||
                sec == 'webhooks' ||
                sec == 'api') {
              widget.onSubNavChanged?.call(
                'Settings > API & Webhooks > Central Warehouse (Zone A)',
                'Manage API access, configure webhooks, and integrate with external systems.',
              );
            } else if (sec == 'audit_log' ||
                sec == 'system_audit_log' ||
                sec == 'activity_logs') {
              widget.onSubNavChanged?.call(
                'Settings > System Audit Log > Central Warehouse (Zone A)',
                'Track all system changes, user actions, and important events across ThreadStock.',
              );
            }
          });
        },
      );
    }
    if (_currentSection == 'transfer_settings' ||
        _currentSection == 'transfer_defaults' ||
        _currentSection == 'transfers_schema') {
      return TransferSettingsView(
        onBackToSettings: () {
          setState(() => _currentSection = 'system_settings');
          widget.onSubNavChanged?.call('Settings', '');
        },
        onSubNavChanged: widget.onSubNavChanged,
        onSelectSection: (sec) {
          setState(() {
            _currentSection = sec;
            if (sec == 'purchasing_defaults' || sec == 'purchasing') {
              widget.onSubNavChanged?.call(
                'Settings > Purchasing Defaults > Central Warehouse (Zone A)',
                'Configure buying, receiving and cost settings for your business.',
              );
            } else if (sec == 'import_export' ||
                sec == 'import_export_studio' ||
                sec == 'import_export_center') {
              widget.onSubNavChanged?.call(
                'Settings > Import / Export Center > Central Warehouse (Zone A)',
                'Import and export your business data with ease. Manage files, track history, and ensure data accuracy.',
              );
            } else if (sec == 'api_webhooks' ||
                sec == 'webhooks' ||
                sec == 'api') {
              widget.onSubNavChanged?.call(
                'Settings > API & Webhooks > Central Warehouse (Zone A)',
                'Manage API access, configure webhooks, and integrate with external systems.',
              );
            } else if (sec == 'audit_log' ||
                sec == 'system_audit_log' ||
                sec == 'activity_logs') {
              widget.onSubNavChanged?.call(
                'Settings > System Audit Log > Central Warehouse (Zone A)',
                'Track all system changes, user actions, and important events across ThreadStock.',
              );
            }
          });
        },
      );
    }
    if (_currentSection == 'import_export' ||
        _currentSection == 'import_export_studio' ||
        _currentSection == 'import_export_center') {
      return ImportExportCenterView(
        onBackToSettings: () {
          setState(() => _currentSection = 'system_settings');
          widget.onSubNavChanged?.call('Settings', '');
        },
        onSubNavChanged: widget.onSubNavChanged,
        onSelectSection: (sec) {
          setState(() {
            _currentSection = sec;
            if (sec == 'purchasing_defaults' || sec == 'purchasing') {
              widget.onSubNavChanged?.call(
                'Settings > Purchasing Defaults > Central Warehouse (Zone A)',
                'Configure buying, receiving and cost settings for your business.',
              );
            } else if (sec == 'transfer_settings' ||
                sec == 'transfer_defaults') {
              widget.onSubNavChanged?.call(
                'Settings > Transfer Settings > Central Warehouse (Zone A)',
                'Configure stock transfer workflows, transit times and receiving preferences.',
              );
            } else if (sec == 'api_webhooks' ||
                sec == 'webhooks' ||
                sec == 'api') {
              widget.onSubNavChanged?.call(
                'Settings > API & Webhooks > Central Warehouse (Zone A)',
                'Manage API access, configure webhooks, and integrate with external systems.',
              );
            } else if (sec == 'audit_log' ||
                sec == 'system_audit_log' ||
                sec == 'activity_logs') {
              widget.onSubNavChanged?.call(
                'Settings > System Audit Log > Central Warehouse (Zone A)',
                'Track all system changes, user actions, and important events across ThreadStock.',
              );
            }
          });
        },
      );
    }
    if (_currentSection == 'api_webhooks' ||
        _currentSection == 'webhooks' ||
        _currentSection == 'api') {
      return ApiWebhooksView(
        onBackToSettings: () {
          setState(() => _currentSection = 'system_settings');
          widget.onSubNavChanged?.call('Settings', '');
        },
        onSubNavChanged: widget.onSubNavChanged,
        onSelectSection: (sec) {
          setState(() {
            _currentSection = sec;
            if (sec == 'purchasing_defaults' || sec == 'purchasing') {
              widget.onSubNavChanged?.call(
                'Settings > Purchasing Defaults > Central Warehouse (Zone A)',
                'Configure buying, receiving and cost settings for your business.',
              );
            } else if (sec == 'transfer_settings' ||
                sec == 'transfer_defaults') {
              widget.onSubNavChanged?.call(
                'Settings > Transfer Settings > Central Warehouse (Zone A)',
                'Configure stock transfer workflows, transit times and receiving preferences.',
              );
            } else if (sec == 'import_export' ||
                sec == 'import_export_studio' ||
                sec == 'import_export_center') {
              widget.onSubNavChanged?.call(
                'Settings > Import / Export Center > Central Warehouse (Zone A)',
                'Import and export your business data with ease. Manage files, track history, and ensure data accuracy.',
              );
            } else if (sec == 'audit_log' ||
                sec == 'system_audit_log' ||
                sec == 'activity_logs') {
              widget.onSubNavChanged?.call(
                'Settings > System Audit Log > Central Warehouse (Zone A)',
                'Track all system changes, user actions, and important events across ThreadStock.',
              );
            }
          });
        },
      );
    }
    if (_currentSection == 'audit_log' ||
        _currentSection == 'system_audit_log' ||
        _currentSection == 'activity_logs') {
      return SystemAuditLogView(
        onBackToSettings: () {
          setState(() => _currentSection = 'system_settings');
          widget.onSubNavChanged?.call('Settings', '');
        },
        onSubNavChanged: widget.onSubNavChanged,
        onSelectSection: (sec) {
          setState(() {
            _currentSection = sec;
            if (sec == 'purchasing_defaults' || sec == 'purchasing') {
              widget.onSubNavChanged?.call(
                'Settings > Purchasing Defaults > Central Warehouse (Zone A)',
                'Configure buying, receiving and cost settings for your business.',
              );
            } else if (sec == 'transfer_settings' ||
                sec == 'transfer_defaults') {
              widget.onSubNavChanged?.call(
                'Settings > Transfer Settings > Central Warehouse (Zone A)',
                'Configure stock transfer workflows, transit times and receiving preferences.',
              );
            } else if (sec == 'import_export' ||
                sec == 'import_export_studio' ||
                sec == 'import_export_center') {
              widget.onSubNavChanged?.call(
                'Settings > Import / Export Center > Central Warehouse (Zone A)',
                'Import and export your business data with ease. Manage files, track history, and ensure data accuracy.',
              );
            } else if (sec == 'api_webhooks' ||
                sec == 'webhooks' ||
                sec == 'api') {
              widget.onSubNavChanged?.call(
                'Settings > API & Webhooks > Central Warehouse (Zone A)',
                'Manage API access, configure webhooks, and integrate with external systems.',
              );
            }
          });
        },
      );
    }
    if (_currentSection == 'sync_queue' ||
        _currentSection == 'system_integration_sync' ||
        _currentSection == 'integration_sync') {
      return SystemIntegrationSyncView(
        onBackToSettings: () {
          setState(() => _currentSection = 'system_settings');
          widget.onSubNavChanged?.call('Settings', '');
        },
        onSubNavChanged: widget.onSubNavChanged,
        onSelectSection: (sec) {
          setState(() {
            _currentSection = sec;
            if (sec == 'integrations') {
              widget.onSubNavChanged?.call(
                'Settings > Integrations',
                'Link e-commerce channels, courier aggregators, and enterprise accounting software.',
              );
            } else if (sec == 'audit_log' ||
                sec == 'system_audit_log' ||
                sec == 'activity_logs') {
              widget.onSubNavChanged?.call(
                'Settings > System Audit Log > Central Warehouse (Zone A)',
                'Track all system changes, user actions, and important events across ThreadStock.',
              );
            }
          });
        },
      );
    }
    if (_currentSection == 'inventory_rules' ||
        _currentSection == 'rules' ||
        _currentSection == 'stock_rules') {
      return InventoryRulesView(
        onBackToSettings: () {
          setState(() => _currentSection = 'system_settings');
          widget.onSubNavChanged?.call('Settings', '');
        },
        onSubNavChanged: widget.onSubNavChanged,
      );
    }
    if (_currentSection == 'barcode_printing' ||
        _currentSection == 'barcode' ||
        _currentSection == 'printing') {
      return BarcodePrintingView(
        onBackToSettings: () {
          setState(() => _currentSection = 'system_settings');
          widget.onSubNavChanged?.call('Settings', '');
        },
        onSubNavChanged: widget.onSubNavChanged,
      );
    }
    if (_currentSection == 'notifications_schema' ||
        _currentSection == 'notification_settings' ||
        _currentSection == 'notifications') {
      return NotificationPreferencesView(
        onBackToSettings: () {
          setState(() => _currentSection = 'system_settings');
          widget.onSubNavChanged?.call('Settings', '');
        },
        onSubNavChanged: widget.onSubNavChanged,
      );
    }
    if (_currentSection == 'integrations') {
      return IntegrationsMarketplaceView(
        onBackToSettings: () {
          setState(() => _currentSection = 'system_settings');
          widget.onSubNavChanged?.call('Settings', '');
        },
        onSubNavChanged: widget.onSubNavChanged,
      );
    }
    if (_currentSection == 'shopify_connector' || _currentSection == 'shopify') {
      return ShopifyConnectorView(
        onBackToIntegrations: () {
          setState(() => _currentSection = 'integrations');
          widget.onSubNavChanged?.call(
            'Settings > Integrations',
            'Link e-commerce channels, courier aggregators, and enterprise accounting software.',
          );
        },
        onSubNavChanged: widget.onSubNavChanged,
      );
    }
    if (_currentSection == 'sales_channels') {
      return SalesChannelsView(
        onBackToSettings: () {
          setState(() => _currentSection = 'system_settings');
          widget.onSubNavChanged?.call('Settings', '');
        },
        onSubNavChanged: widget.onSubNavChanged,
      );
    }
    if (_currentSection == 'pos_channel' || _currentSection == 'instore_pos') {
      return InStorePosChannelView(
        onBackToChannels: () {
          setState(() => _currentSection = 'sales_channels');
          widget.onSubNavChanged?.call(
            'Settings > Sales Channels',
            'Connect, manage and configure active physical or digital checkout points of sale.',
          );
        },
      );
    }
    if (_currentSection == 'security_sso' || _currentSection == 'security') {
      return SecurityAuthenticationView(
        onBackToSettings: () {
          setState(() => _currentSection = 'system_settings');
          widget.onSubNavChanged?.call('Settings', '');
        },
      );
    }
    if (_currentSection == 'edit_role') {
      return EditRoleView(
        onCancel: () {
          setState(() => _currentSection = 'roles_permissions');
          widget.onSubNavChanged?.call(
            'Roles & Permissions',
            'Manage workspace roles, permissions and granular system capabilities.',
          );
        },
        onSave: (role) {
          setState(() => _currentSection = 'roles_permissions');
          widget.onSubNavChanged?.call(
            'Roles & Permissions',
            'Manage workspace roles, permissions and granular system capabilities.',
          );
        },
        onCreateCustomRole: () {
          setState(() => _currentSection = 'edit_role');
        },
      );
    }
    if (_currentSection == 'roles_permissions') {
      return RolesPermissionsView(
        onSubNavChanged: (title, subtitle) {
          widget.onSubNavChanged?.call(title, subtitle);
        },
      );
    }
    if (_currentSection == 'team_directory') {
      return TeamAccessView(
        onTabChanged: (section) {
          setState(() => _currentSection = section);
          if (section == 'roles_permissions') {
            widget.onSubNavChanged?.call('Roles & Permissions', 'Manage workspace roles, permissions and granular system capabilities.');
          } else if (section == 'locations') {
            widget.onSubNavChanged?.call('Locations', 'Manage locations and inventory nodes.');
          } else if (section == 'integrations') {
            widget.onSubNavChanged?.call('Settings > Integrations', 'Link e-commerce channels, courier aggregators, and enterprise accounting software.');
          } else if (section == 'system_settings') {
            widget.onSubNavChanged?.call('System Settings', '');
          }
        },
      );
    }
    if (_currentSection == 'documents_templates') {
      return const DocumentSettingsView();
    }
    if (_currentSection == 'taxes_currency') {
      return const TaxesCurrencyView();
    }
    if (_currentSection == 'add_location') {
      return AddLocationView(
        onCancel: () {
          setState(() => _currentSection = 'locations');
          widget.onSubNavChanged?.call(
            'Locations',
            'Settings > Locations',
          );
        },
        onCreated: (name) {
          setState(() => _currentSection = 'locations');
          widget.onSubNavChanged?.call(
            'Locations',
            'Settings > Locations',
          );
        },
      );
    }
    if (_currentSection == 'locations') {
      return LocationsView(
        onAddLocation: () {
          setState(() => _currentSection = 'add_location');
          widget.onSubNavChanged?.call(
            'Add Location',
            'Settings → Locations → Add Location',
          );
        },
      );
    }
    if (_currentSection == 'business_profile') {
      return const BusinessProfileView();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Sub-Navigation Menu
        _buildSubNav(),

        // Vertical Hairline Divider
        Container(
          width: 1,
          height: double.infinity,
          color: const Color(0xFFEADBCA),
        ),

        // Right Main Content Panel
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 28,
              right: 36,
              top: 24,
              bottom: 40,
            ),
            child: _buildSelectedPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedPanel() {
    switch (_selectedNavIndex) {
      case 0:
        return _buildPreferencesPanel();
      case 1:
        return _buildSubscriptionPanel();
      case 2:
        return _buildBillingPanel();
      case 3:
        return _buildHelpPanel();
      case 4:
      default:
        return _buildStatusPanel();
    }
  }

  // ========================================================
  // LEFT SUB-NAVIGATION
  // ========================================================
  Widget _buildSubNav() {
    return SizedBox(
      width: 224,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'SYSTEM SETTINGS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: const Color(0xFF8A8175),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isSelected = _selectedNavIndex == index;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _SubNavItemWidget(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => _onNavSelected(index),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // PREFERENCES PANEL
  // ========================================================
  Widget _buildPreferencesPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Appearance & Localization
        _buildCard(
          icon: Icons.wb_sunny_outlined,
          title: 'Appearance & Localization',
          subtitle:
              'Customize how ThreadStock looks and behaves for your workspace.',
          children: [
            _buildSettingRow(
              title: 'Visual Theme',
              subtitle: 'Choose the interface theme for your workspace.',
              control: _buildSegmentedControl(
                options: const ['Light Theme', 'Dark Theme', 'System Default'],
                selected: _visualTheme,
                onChanged: (val) => setState(() => _visualTheme = val),
              ),
            ),
            _buildDivider(),
            _buildSettingRow(
              title: 'Primary System Language',
              subtitle: 'This will be used across the application.',
              control: _buildDropdown(
                value: _primaryLanguage,
                options: const [
                  'English (Global US)',
                  'English (UK)',
                  'French (Français)',
                  'Italian (Italiano)',
                  'Arabic (العربية)',
                  'Hindi (हिन्दी)',
                ],
                onChanged: (val) => setState(() => _primaryLanguage = val),
              ),
            ),
            _buildDivider(),
            _buildSettingRow(
              title: 'Preferred Date Format',
              subtitle: 'Choose how dates appear across the application.',
              control: _buildDropdown(
                value: _dateFormat,
                options: const [
                  'DD/MM/YYYY',
                  'MM/DD/YYYY',
                  'YYYY-MM-DD',
                ],
                onChanged: (val) => setState(() => _dateFormat = val),
              ),
            ),
            _buildDivider(),
            _buildSettingRow(
              title: 'First Day of Week',
              subtitle: 'Set the start day for calendar views and reports.',
              control: _buildSegmentedControl(
                options: const ['Monday', 'Sunday'],
                selected: _firstDayOfWeek,
                onChanged: (val) => setState(() => _firstDayOfWeek = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Card 2: Operational Defaults
        _buildCard(
          icon: Icons.layers_outlined,
          title: 'Operational Defaults',
          subtitle: 'Configure default behaviours for your day-to-day operations.',
          children: [
            _buildSettingRow(
              title: 'Default Landing Dashboard',
              subtitle: 'Choose which dashboard to show after sign in.',
              control: _buildDropdown(
                value: _defaultLandingDashboard,
                options: const [
                  'Central Warehouse (Zone A)',
                  'Flagship Delhi (Zone B)',
                  'Mumbai Boutique (Zone C)',
                  'Global Executive Overview',
                ],
                onChanged: (val) =>
                    setState(() => _defaultLandingDashboard = val),
              ),
            ),
            _buildDivider(),
            _buildSettingRow(
              title: 'Enable Guided Onboarding',
              subtitle: 'Show helpful guidance for new team members.',
              control: _buildSwitch(
                value: _enableGuidedOnboarding,
                onChanged: (val) =>
                    setState(() => _enableGuidedOnboarding = val),
              ),
            ),
            _buildDivider(),
            _buildSettingRow(
              title: 'Preferred Table Density',
              subtitle: 'Adjust the density of tables across the application.',
              control: _buildSegmentedControl(
                options: const ['Comfortable View', 'Compact Density'],
                selected: _tableDensity,
                onChanged: (val) => setState(() => _tableDensity = val),
              ),
            ),
            _buildDivider(),
            _buildSettingRow(
              title: 'Default Rows Per Page',
              subtitle: 'Set the default number of rows in tables.',
              control: _buildDropdown(
                value: _defaultRowsPerPage,
                options: const [
                  '25 Items',
                  '50 Items',
                  '100 Items',
                  '250 Items',
                ],
                onChanged: (val) =>
                    setState(() => _defaultRowsPerPage = val),
              ),
            ),
            _buildDivider(),
            _buildSettingRow(
              title: 'Enable Quick Keyboard Shortcuts',
              subtitle: 'Use keyboard shortcuts for faster navigation.',
              control: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => KeyboardShortcutsDialog.show(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF9E7744),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      'View shortcuts',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildSwitch(
                    value: _enableQuickKeyboardShortcuts,
                    onChanged: (val) =>
                        setState(() => _enableQuickKeyboardShortcuts = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ========================================================
  // SUBSCRIPTION & PLAN PANEL (Exact visual match to screenshot)
  // ========================================================
  Widget _buildSubscriptionPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Current Plan Highlight Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF7F2).withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8DFD3), width: 1.0),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFCF9F4),
                Color(0xFFFAF6EE),
                Color(0xFFF7EFE1),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2A231A).withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Crown Icon + Plan Title + Active Badge + Renewal
              Expanded(
                child: Row(
                  children: [
                    // Circular Crown Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFBF7),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFDECDB9)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.workspace_premium_outlined,
                          size: 24,
                          color: Color(0xFFBA8A55),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Professional Plan',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF161412),
                                  ),
                                ),
                              ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF2E6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFDECDB9),
                              ),
                            ),
                            child: Text(
                              'ACTIVE PLAN',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.7,
                                color: const Color(0xFF9E7744),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: const Color(0xFF6B6358),
                          ),
                          children: [
                            const TextSpan(
                              text: 'Your package renews automatically on ',
                            ),
                            TextSpan(
                              text: 'October 15, 2024.',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E1C1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

              // Right: Pricing Info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹4,999',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF161412),
                        ),
                      ),
                      Text(
                        ' /month',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6B6358),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Billed annually (Save 15%)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF7A7268),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // 2. Resource Allocation & Limits Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF7F2).withOpacity(0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8DFD3), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2A231A).withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resource Allocation & Limits',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF161412),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Track your current usage across key resources.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6B6358),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Last updated • Today, 10:24 AM',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8C8478),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4 Resource Metric Cards
              Row(
                children: [
                  Expanded(
                    child: _buildResourceMetricCard(
                      icon: Icons.location_on_outlined,
                      label: 'Locations Accessed',
                      value: '3 / 5',
                      fraction: 3 / 5,
                      percentText: '60%',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildResourceMetricCard(
                      icon: Icons.people_outline_rounded,
                      label: 'Team Seats',
                      value: '5 / 15',
                      fraction: 5 / 15,
                      percentText: '33%',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildResourceMetricCard(
                      icon: Icons.all_inbox_outlined,
                      label: 'Catalog Products',
                      value: '1,247 / 10K',
                      fraction: 1247 / 10000,
                      percentText: '12%',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildResourceMetricCard(
                      icon: Icons.cloud_outlined,
                      label: 'Weekly API Calls',
                      value: '48K / 100K',
                      fraction: 48 / 100,
                      percentText: '48%',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // 3. Tier Comparison Matrix Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF7F2).withOpacity(0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8DFD3), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2A231A).withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Matrix Header with Upgrade CTA
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tier Comparison Matrix',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF161412),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Compare features across plans and find the right fit for your business.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6B6358),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1C1A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Upgrade to Enterprise Plan',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Comparison Table
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE8DFD3)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2.8),
                    1: FlexColumnWidth(2.0),
                    2: FlexColumnWidth(2.4),
                    3: FlexColumnWidth(2.0),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    // Header Row
                    TableRow(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7F2EB),
                      ),
                      children: [
                        _buildTableHeaderCell('CAPABILITIES', isLeft: true),
                        _buildTableHeaderCell('STARTER'),
                        _buildTableHeaderCell(
                          'PROFESSIONAL (CURRENT)',
                          isHighlighted: true,
                        ),
                        _buildTableHeaderCell('ENTERPRISE'),
                      ],
                    ),

                    // Row 1: Max Locations
                    _buildMatrixRow(
                      capability: 'Max Locations',
                      starter: '1 Node',
                      professional: '5 Nodes',
                      enterprise: 'Unlimited',
                      isProBold: true,
                    ),

                    // Row 2: Users / Members
                    _buildMatrixRow(
                      capability: 'Users / Members',
                      starter: '2 Seats',
                      professional: '15 Seats',
                      enterprise: 'Unlimited',
                      isProBold: true,
                    ),

                    // Row 3: Products Capacity
                    _buildMatrixRow(
                      capability: 'Products Capacity',
                      starter: '1,000 SKUs',
                      professional: '10,000 SKUs',
                      enterprise: 'Unlimited',
                      isProBold: true,
                    ),

                    // Row 4: Atelier AI Integration
                    _buildMatrixRow(
                      capability: 'Atelier AI Integration',
                      starter: 'Not Available',
                      professional: 'Standard AI Assistant',
                      enterprise: 'Fine-tuned models',
                      isProBold: false,
                    ),

                    // Row 5: API Capabilities
                    _buildMatrixRow(
                      capability: 'API Capabilities',
                      starter: 'Read-only access',
                      professional: 'Full REST Access',
                      enterprise: 'Webhooks & Web REST',
                      isProBold: true,
                    ),

                    // Row 6: Monthly Price
                    _buildMatrixRow(
                      capability: 'Monthly Price',
                      starter: '₹1,499',
                      professional: '₹4,999',
                      enterprise: 'Custom Quote',
                      isProBold: true,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4. Contact Sales Bottom Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF7F2).withOpacity(0.92),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8DFD3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFBA8A55), width: 1.2),
                      ),
                      child: const Center(
                        child: Text(
                          'i',
                          style: TextStyle(
                            color: Color(0xFFBA8A55),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Need a custom plan? Contact our sales team for tailored solutions.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF5E574E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.85),
                  foregroundColor: const Color(0xFF1E1C1A),
                  side: const BorderSide(color: Color(0xFFDECDB9), width: 1.1),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Contact Sales',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1C1A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: Color(0xFFBA8A55),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========================================================
  // MATRIX HELPER BUILDERS
  // ========================================================
  Widget _buildTableHeaderCell(
    String label, {
    bool isLeft = false,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      color: isHighlighted ? const Color(0xFFFAF5EC) : Colors.transparent,
      alignment: isLeft ? Alignment.centerLeft : Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: isHighlighted
              ? const Color(0xFFBA8A55)
              : const Color(0xFF6B6358),
        ),
      ),
    );
  }

  TableRow _buildMatrixRow({
    required String capability,
    required String starter,
    required String professional,
    required String enterprise,
    bool isProBold = false,
    bool isLast = false,
  }) {
    return TableRow(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFEDE5DA), width: 1.0),
              ),
      ),
      children: [
        // Capabilities (Left)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Text(
            capability,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E1C1A),
            ),
          ),
        ),

        // Starter (Center)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Center(
            child: Text(
              starter,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF5E574E),
              ),
            ),
          ),
        ),

        // Professional (Center - Highlighted column background)
        Container(
          color: const Color(0xFFFAF5EC),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Center(
            child: Text(
              professional,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: isProBold ? FontWeight.w700 : FontWeight.w500,
                color: const Color(0xFF161412),
              ),
            ),
          ),
        ),

        // Enterprise (Center)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Center(
            child: Text(
              enterprise,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF5E574E),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Single Resource Metric Usage Card
  Widget _buildResourceMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required double fraction,
    required String percentText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEADBCA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF6F0),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE8DFD3)),
                ),
                child: Center(
                  child: Icon(icon, size: 15, color: const Color(0xFFBA8A55)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B6358),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E1C1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: fraction.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: const Color(0xFFEDE5DA),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFBA8A55),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                percentText,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7A7268),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // OTHER SUB-TABS (Clean and interactive)
  // ========================================================
  Widget _buildBillingPanel() {
    return _buildCard(
      icon: Icons.receipt_long_outlined,
      title: 'Billing & Invoicing',
      subtitle: 'Manage payment instruments, corporate GSTIN, and past statements.',
      children: [
        _buildSettingRow(
          title: 'Payment Method',
          subtitle: 'Corporate Visa ending in •••• 4242 (Expires 08/29)',
          control: Text(
            'Primary Default',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2E6B4B),
            ),
          ),
        ),
        _buildDivider(),
        _buildSettingRow(
          title: 'Billing Contact Email',
          subtitle: 'finance@maisonatelier.com (Receives invoices and receipts)',
          control: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E1C1A),
              side: const BorderSide(color: Color(0xFFDECDB9)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Edit Email'),
          ),
        ),
      ],
    );
  }

  // ========================================================
  // HELP & SUPPORT PANEL (Exact visual match to screenshot)
  // ========================================================
  Widget _buildHelpPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tier 1: Top 4 Quick Resource Cards
        Row(
          children: [
            Expanded(
              child: _buildTopQuickCard(
                icon: Icons.menu_book_outlined,
                title: 'Documentation',
                subtitle: 'Comprehensive step-by-step feature guides',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildTopQuickCard(
                icon: Icons.smart_display_outlined,
                title: 'Video Tutorials',
                subtitle: 'Screencasts detailing Atelier OS setup and workflows',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildTopQuickCard(
                icon: Icons.people_outline_rounded,
                title: 'Community Forum',
                subtitle: 'Discuss best stock strategies with global admins',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildTopQuickCard(
                icon: Icons.code_rounded,
                title: 'API Reference',
                subtitle: 'Guides for webhooks, custom nodes and imports',
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Tier 2: Middle Split Row (Contact Technical Support & Recent Support Tickets)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Contact Technical Support Card
            Expanded(
              flex: 12,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2).withOpacity(0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8DFD3), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2A231A).withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAF6F0),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFDECDB9)),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.mail_outline_rounded,
                                    size: 19,
                                    color: Color(0xFFBA8A55),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'Contact Technical Support',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF161412),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF2E6),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFDECDB9)),
                          ),
                          child: Text(
                            'PRIORITY ASSISTANCE',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                              color: const Color(0xFF9E7744),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Send us a message and our team will get back to you shortly.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B6358),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Field 1: Subject
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDCCFBE)),
                      ),
                      child: TextField(
                        controller: _supportSubjectController,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1E1C1A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Subject of query',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: const Color(0xFF9E958A),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Field 2: Category Dropdown
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDCCFBE)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSupportCategory,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: Color(0xFF7A7268),
                          ),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF1E1C1A),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Inventory Reconciliation & Auditing',
                              child: Text('Inventory Reconciliation & Auditing'),
                            ),
                            DropdownMenuItem(
                              value: 'Barcode Scanner & POS Hardware',
                              child: Text('Barcode Scanner & POS Hardware'),
                            ),
                            DropdownMenuItem(
                              value: 'Shopify & Multi-channel Sync',
                              child: Text('Shopify & Multi-channel Sync'),
                            ),
                            DropdownMenuItem(
                              value: 'Billing & Subscription Inquiries',
                              child: Text('Billing & Subscription Inquiries'),
                            ),
                            DropdownMenuItem(
                              value: 'User Roles & Location Permissions',
                              child: Text('User Roles & Location Permissions'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedSupportCategory = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Field 3: Multiline Details
                    Container(
                      height: 110,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDCCFBE)),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _supportDescController,
                              maxLines: null,
                              onChanged: (_) => setState(() {}),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF1E1C1A),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Explain details of your operational issue...',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: const Color(0xFF9E958A),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              '${_supportDescController.text.length}/1000',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF8C8478),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bottom Action Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.attach_file_rounded,
                                size: 18,
                                color: Color(0xFF7A7268),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Attach stock logs or reports',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF5E574E),
                                      ),
                                    ),
                                    Text(
                                      'PDF, CSV, XLS, or images (max 10 MB)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: const Color(0xFF8C8478),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF171717),
                                Color(0xFF1D1B19),
                                Color(0xFF30271F),
                                Color(0xFF423225),
                              ],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x2814100C),
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {},
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 11,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Submit Request',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFFAF7F2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 15,
                                      color: Color(0xFFD3A75F),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 18),

            // Right: Recent Support Tickets Card
            Expanded(
              flex: 11,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2).withOpacity(0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8DFD3), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2A231A).withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAF6F0),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFDECDB9)),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.description_outlined,
                                    size: 19,
                                    color: Color(0xFFBA8A55),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'Recent Support Tickets',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF161412),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {},
                          child: Row(
                            children: [
                              Text(
                                'View All',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF9E7744),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: Color(0xFF9E7744),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track the status of your recent support requests.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B6358),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Tickets Table
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.4),
                        1: FlexColumnWidth(3.4),
                        2: FlexColumnWidth(1.8),
                        3: FlexColumnWidth(2.0),
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: [
                        // Header
                        TableRow(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFFEDE5DA),
                                width: 1.0,
                              ),
                            ),
                          ),
                          children: [
                            _buildTicketHeaderCell('ID'),
                            _buildTicketHeaderCell('ISSUE SUBJECT'),
                            _buildTicketHeaderCell('STATUS', isCenter: true),
                            _buildTicketHeaderCell('CREATED', isRight: true),
                          ],
                        ),

                        // Ticket 1
                        _buildTicketRow(
                          id: 'T-8924',
                          subject: 'API Outages during stock count sync',
                          status: 'Open',
                          statusBg: const Color(0xFFFFF4E5),
                          statusBorder: const Color(0xFFFED7AA),
                          statusColor: const Color(0xFFC26100),
                          created: 'Oct 10, 2024',
                        ),

                        // Ticket 2
                        _buildTicketRow(
                          id: 'T-8411',
                          subject: 'Wrong collection matrix matching',
                          status: 'Resolved',
                          statusBg: const Color(0xFFE8F5E9),
                          statusBorder: const Color(0xFFC8E6C9),
                          statusColor: const Color(0xFF2E7D32),
                          created: 'Oct 08, 2024',
                        ),

                        // Ticket 3
                        _buildTicketRow(
                          id: 'T-7994',
                          subject: 'Add Custom Regional Fields',
                          status: 'Pending',
                          statusBg: const Color(0xFFEBF3FA),
                          statusBorder: const Color(0xFFCFE2F3),
                          statusColor: const Color(0xFF1B65A4),
                          created: 'Oct 05, 2024',
                        ),

                        // Ticket 4
                        _buildTicketRow(
                          id: 'T-7781',
                          subject: 'Barcode scanner not detecting',
                          status: 'Resolved',
                          statusBg: const Color(0xFFE8F5E9),
                          statusBorder: const Color(0xFFC8E6C9),
                          statusColor: const Color(0xFF2E7D32),
                          created: 'Oct 02, 2024',
                        ),

                        // Ticket 5
                        _buildTicketRow(
                          id: 'T-7612',
                          subject: 'Bulk import validation errors',
                          status: 'Closed',
                          statusBg: const Color(0xFFF1ECE5),
                          statusBorder: const Color(0xFFE0D7CC),
                          statusColor: const Color(0xFF6E665C),
                          created: 'Sep 28, 2024',
                          isLast: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Tier 3: Bottom Additional Support Resources Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF7F2).withOpacity(0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8DFD3), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2A231A).withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF6F0),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFDECDB9)),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 20,
                        color: Color(0xFFBA8A55),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Additional Support Resources',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF161412),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Explore more ways to get help and learn.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6B6358),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4 Bottom Quick Resource Sub-Cards
              Row(
                children: [
                  Expanded(
                    child: _buildBottomResourceCard(
                      icon: Icons.menu_book_outlined,
                      title: 'Knowledge Base',
                      subtitle: 'Search articles and guides',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildBottomResourceCard(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Live Chat',
                      subtitle: 'Chat with our support team',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildBottomResourceCard(
                      icon: Icons.file_download_outlined,
                      title: 'Download Diagnostics',
                      subtitle: 'Help us troubleshoot faster',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildBottomResourceCard(
                      icon: Icons.mail_outline_rounded,
                      title: 'Email Support',
                      subtitle: 'support@threadstock.ai',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper: Top Quick Resource Card
  Widget _buildTopQuickCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2).withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8DFD3), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF6F0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDECDB9)),
                ),
                child: Center(
                  child: Icon(icon, size: 18, color: const Color(0xFFBA8A55)),
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 15,
                color: Color(0xFFBA8A55),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF161412),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B6358),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Ticket Header Cell
  Widget _buildTicketHeaderCell(
    String text, {
    bool isCenter = false,
    bool isRight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Align(
        alignment: isCenter
            ? Alignment.center
            : (isRight ? Alignment.centerRight : Alignment.centerLeft),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: const Color(0xFF8C8478),
          ),
        ),
      ),
    );
  }

  // Helper: Ticket Table Row
  TableRow _buildTicketRow({
    required String id,
    required String subject,
    required String status,
    required Color statusBg,
    required Color statusBorder,
    required Color statusColor,
    required String created,
    bool isLast = false,
  }) {
    return TableRow(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFEDE5DA), width: 1.0),
              ),
      ),
      children: [
        // ID
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            id,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1C1A),
            ),
          ),
        ),

        // Subject
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            subject,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF3E3831),
            ),
          ),
        ),

        // Status
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusBorder),
              ),
              child: Text(
                status,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ),
        ),

        // Created
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              created,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF7A7268),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper: Bottom Quick Resource Card
  Widget _buildBottomResourceCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEADBCA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 18, color: const Color(0xFFBA8A55)),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: Color(0xFFBA8A55),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1C1A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B6358),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // SYSTEM STATUS PANEL (Exact visual match to mockup)
  // ========================================================
  Widget _buildStatusPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tier 1: Overall Status Banner
        _buildOverallStatusBanner(),
        const SizedBox(height: 20),

        // Tier 2: Active Core Services Card
        _buildActiveCoreServicesCard(),
        const SizedBox(height: 20),

        // Tier 3: Bottom Split Row (Recent Incidents & Scheduled Maintenance)
        _buildBottomStatusRow(),
      ],
    );
  }

  // Tier 1: Top Status Banner
  Widget _buildOverallStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD0E6D8), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left checkmark circle
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.check_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Systems Operational',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B4D2E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Atelier cloud platform is operating normally. No global incidents reported in past 24 hours.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF4A6B56),
                  ),
                ),
              ],
            ),
          ),

          // Right timestamp with status dot
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Last updated',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Oct 15, 2024, 10:24 AM',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _currentSection = 'sync_queue');
                  widget.onSubNavChanged?.call(
                    'Sync Queue > System Status > Sync',
                    'Monitor real-time data flows between ThreadStock and connected external integrations.',
                  );
                },
                icon: const Icon(Icons.sync_rounded, size: 15, color: Color(0xFF1B4D2E)),
                label: Text(
                  'Live Sync Queue',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B4D2E),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFB0D5BE)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Tier 2: Active Core Services Card
  Widget _buildActiveCoreServicesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2).withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DFD3), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF6F0),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFDECDB9)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.dns_outlined,
                          size: 20,
                          color: Color(0xFFBA8A55),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Core Services',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF161412),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Real-time status of all critical system components.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF6B6358),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Overall Uptime metrics
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Overall Uptime',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF8C8478),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.bar_chart_rounded,
                        size: 16,
                        color: Color(0xFFBA8A55),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '99.92%',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF161412),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Last 30 days',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF8C8478),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFEDE5DA), height: 1),
          const SizedBox(height: 6),

          // 6 Core Service Rows
          _buildServiceRow(
            icon: Icons.dns_rounded,
            title: 'Core Retail Database Platform',
            uptime: '99.98% uptime',
            description: 'Primary database, authentication and core data services.',
            status: 'Operational',
            isDegraded: false,
          ),
          _buildServiceDivider(),
          _buildServiceRow(
            icon: Icons.cloud_outlined,
            title: 'Real-time Inventory Sync Engine',
            uptime: '99.92% uptime',
            description: 'Synchronizes inventory across all locations in real-time.',
            status: 'Operational',
            isDegraded: false,
          ),
          _buildServiceDivider(),
          _buildServiceRow(
            icon: Icons.credit_card_outlined,
            title: 'POS and Payment Gateways Processing',
            uptime: '100% uptime',
            description: 'Payment processing, card terminals and transaction services.',
            status: 'Operational',
            isDegraded: false,
          ),
          _buildServiceDivider(),
          _buildServiceRow(
            icon: Icons.psychology_outlined,
            title: 'Atelier OS AI Prediction Engines',
            uptime: '94.20% uptime',
            description: 'AI forecasting, recommendation and analytics models.',
            status: 'Degraded Performance',
            isDegraded: true,
          ),
          _buildServiceDivider(),
          _buildServiceRow(
            icon: Icons.alt_route_rounded,
            title: 'Global Warehousing API Integrations',
            uptime: '99.95% uptime',
            description: 'Third-party integrations and warehouse sync services.',
            status: 'Operational',
            isDegraded: false,
          ),
          _buildServiceDivider(),
          _buildServiceRow(
            icon: Icons.bar_chart_rounded,
            title: 'Executive Report & Analytics Engine',
            uptime: '99.90% uptime',
            description: 'Business intelligence and reporting services.',
            status: 'Operational',
            isDegraded: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDivider() {
    return const Divider(color: Color(0xFFF0E8DD), height: 1);
  }

  Widget _buildServiceRow({
    required IconData icon,
    required String title,
    required String uptime,
    required String description,
    required String status,
    required bool isDegraded,
    bool isLast = false,
  }) {
    final statusColor = isDegraded ? const Color(0xFFC26100) : const Color(0xFF2E7D32);
    final statusBg = isDegraded ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9);
    final statusBorder = isDegraded ? const Color(0xFFFFE0B2) : const Color(0xFFC8E6C9);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Service Icon inside circular badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusBg,
              shape: BoxShape.circle,
              border: Border.all(color: statusBorder),
            ),
            child: Center(
              child: Icon(icon, size: 18, color: statusColor),
            ),
          ),
          const SizedBox(width: 14),

          // Title & Uptime column
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E1C1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  uptime,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF7A7268),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Description column (Middle)
          Expanded(
            flex: 4,
            child: Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF5E574E),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Status Pill with dot
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Right Chevron
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: Color(0xFF9E958A),
          ),
        ],
      ),
    );
  }

  // Tier 3: Bottom Split Row (Recent Incidents & Scheduled Maintenance)
  Widget _buildBottomStatusRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Recent Incidents
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2).withOpacity(0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8DFD3), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2A231A).withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF6F0),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFDECDB9)),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: Color(0xFFBA8A55),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Recent Incidents (Past 7 Days)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF161412),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {},
                      child: Row(
                        children: [
                          Text(
                            'View All',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF9E7744),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Color(0xFF9E7744),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'A summary of recent incidents and their resolution status.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B6358),
                  ),
                ),
                const SizedBox(height: 16),

                // Incident Inner Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.90),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEADBCA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Oct 02: AI Recommendation Outage',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E1C1A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: const Color(0xFFC8E6C9)),
                            ),
                            child: Text(
                              'Resolved',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Duration: 14 mins  |  Caused by cache replication latency.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7A7268),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AI recommendation features were temporarily unavailable.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF5E574E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 18),

        // Right: Scheduled Maintenance
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2).withOpacity(0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8DFD3), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2A231A).withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF6F0),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFDECDB9)),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.build_outlined,
                                size: 18,
                                color: Color(0xFFBA8A55),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Scheduled Maintenance',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF161412),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {},
                      child: Row(
                        children: [
                          Text(
                            'View All',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF9E7744),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Color(0xFF9E7744),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Upcoming maintenance windows and system updates.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B6358),
                  ),
                ),
                const SizedBox(height: 16),

                // Maintenance Inner Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.90),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEADBCA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Oct 18: Major Database Indexing',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E1C1A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: const Color(0xFFDBEAFE)),
                            ),
                            child: Text(
                              'Scheduled',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '02:00 AM – 04:00 AM IST',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7A7268),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stock counts might reflect slight sync delays during this window.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF5E574E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ========================================================
  // REUSABLE CARD & SETTING ROW BUILDERS
  // ========================================================
  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2).withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DFD3), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Circular Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF6F0),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFDECDB9)),
                  ),
                  child: Center(
                    child: Icon(icon, size: 20, color: const Color(0xFFBA8A55)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF161412),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6B6358),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFEDE5DA), height: 1),

          // Setting Rows
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required String title,
    required String subtitle,
    required Widget control,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Label + Explanation
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E1C1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B6358),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // Right: Interactive Control
          control,
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Color(0xFFEDE5DA), height: 1);
  }

  // Segmented Control (matches mockup with gold border on selected option)
  Widget _buildSegmentedControl({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5DACD)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          final isSelected = option == selected;
          return InkWell(
            onTap: () => onChanged(option),
            borderRadius: BorderRadius.circular(7),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFBF7EE) : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: isSelected
                    ? Border.all(color: const Color(0xFFBA8A55), width: 1.2)
                    : null,
              ),
              child: Text(
                option,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFF1E1C1A)
                      : const Color(0xFF6B6358),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Dropdown Box with chevron
  Widget _buildDropdown({
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCCFBE)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(value) ? value : options.first,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: Color(0xFF7A7268),
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(8),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF1E1C1A),
          ),
          items: options.map((opt) {
            return DropdownMenuItem(
              value: opt,
              child: Text(opt),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              onChanged(val);
            }
          },
        ),
      ),
    );
  }

  // Smooth warm caramel switch toggle matching the mockup
  Widget _buildSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 44,
          height: 24,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: value ? const Color(0xFF553519) : const Color(0xFFD8CFBE),
          ),
          child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 19,
            height: 19,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}

class _SettingsNavItem {
  const _SettingsNavItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class _SubNavItemWidget extends StatefulWidget {
  const _SubNavItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _SettingsNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_SubNavItemWidget> createState() => _SubNavItemWidgetState();
}

class _SubNavItemWidgetState extends State<_SubNavItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected
        ? const Color(0xFFF3ECE2)
        : (_isHovered ? const Color(0xFFF8F4ED) : Colors.transparent);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                widget.item.icon,
                size: 18,
                color: widget.isSelected
                    ? const Color(0xFF1E1C1A)
                    : (_isHovered
                        ? const Color(0xFF3E3831)
                        : const Color(0xFF6B6358)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : (_isHovered ? FontWeight.w500 : FontWeight.w400),
                    color: widget.isSelected
                        ? const Color(0xFF1E1C1A)
                        : (_isHovered
                            ? const Color(0xFF2C2721)
                            : const Color(0xFF4E473E)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
