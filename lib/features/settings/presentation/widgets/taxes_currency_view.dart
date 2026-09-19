// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';

class TaxProfileItem {
  final String id;
  final String name;
  final double rate;
  final String type; // 'Exclusive' or 'Inclusive'
  final String regionsApplied;
  final bool isActive;

  const TaxProfileItem({
    required this.id,
    required this.name,
    required this.rate,
    required this.type,
    required this.regionsApplied,
    this.isActive = true,
  });

  TaxProfileItem copyWith({
    String? id,
    String? name,
    double? rate,
    String? type,
    String? regionsApplied,
    bool? isActive,
  }) {
    return TaxProfileItem(
      id: id ?? this.id,
      name: name ?? this.name,
      rate: rate ?? this.rate,
      type: type ?? this.type,
      regionsApplied: regionsApplied ?? this.regionsApplied,
      isActive: isActive ?? this.isActive,
    );
  }
}

class TaxesCurrencyView extends StatefulWidget {
  const TaxesCurrencyView({super.key});

  @override
  State<TaxesCurrencyView> createState() => _TaxesCurrencyViewState();
}

class _TaxesCurrencyViewState extends State<TaxesCurrencyView> {
  // Currency Settings
  String _selectedCurrency = 'INR';
  String _symbolPosition = 'prefix'; // 'prefix' or 'suffix'
  int _decimalPlaces = 2;
  String _thousandsSeparator = 'comma'; // 'comma', 'dot', 'space'

  // Tax Assignment Rules
  bool _perProductRule = true;
  bool _perLocationRule = true;
  bool _perChannelRule = false;

  // Tax Profiles List
  final List<TaxProfileItem> _taxProfiles = [
    const TaxProfileItem(
      id: 'gst_18',
      name: 'GST 18%',
      rate: 18.00,
      type: 'Exclusive',
      regionsApplied: 'All Domestic Zones, Maharashtra ...',
      isActive: true,
    ),
    const TaxProfileItem(
      id: 'gst_12',
      name: 'GST 12%',
      rate: 12.00,
      type: 'Exclusive',
      regionsApplied: 'Selected Handloom categories, ...',
      isActive: true,
    ),
    const TaxProfileItem(
      id: 'gst_5',
      name: 'GST 5%',
      rate: 5.00,
      type: 'Inclusive',
      regionsApplied: 'Raw fabrics, cotton yarn imports ...',
      isActive: true,
    ),
    const TaxProfileItem(
      id: 'zero_rated',
      name: 'Zero-rated (SEZ)',
      rate: 0.00,
      type: 'Exclusive',
      regionsApplied: 'Special Economic Zones, Internat...',
      isActive: true,
    ),
  ];

  String _getCurrencySymbol() {
    switch (_selectedCurrency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'AED':
        return 'AED ';
      case 'INR':
      default:
        return '₹';
    }
  }

  String _getFormattedPreview() {
    final sym = _getCurrencySymbol();
    String numPart;
    if (_selectedCurrency == 'INR') {
      numPart = '1,23,456';
    } else {
      numPart = '123,456';
    }

    if (_thousandsSeparator == 'dot') {
      numPart = numPart.replaceAll(',', '.');
    } else if (_thousandsSeparator == 'space') {
      numPart = numPart.replaceAll(',', ' ');
    }

    String decPart = '';
    if (_decimalPlaces > 0) {
      final decSep = _thousandsSeparator == 'dot' ? ',' : '.';
      decPart = '$decSep${'789'.substring(0, _decimalPlaces.clamp(0, 3))}';
    }

    if (_symbolPosition == 'suffix') {
      return '$numPart$decPart $sym'.trim();
    }
    return '$sym$numPart$decPart';
  }

  String _getFormattedWords() {
    if (_selectedCurrency == 'INR') {
      return 'One Lakh Twenty Three Thousand Four Hundred Fifty Six and Seventy Eight Paise';
    } else if (_selectedCurrency == 'USD') {
      return 'One Hundred Twenty Three Thousand Four Hundred Fifty Six Dollars and Seventy Eight Cents';
    } else if (_selectedCurrency == 'EUR') {
      return 'One Hundred Twenty Three Thousand Four Hundred Fifty Six Euros and Seventy Eight Cents';
    }
    return 'One Hundred Twenty Three Thousand Four Hundred Fifty Six Units';
  }

  void _showAddTaxProfileDialog() {
    final nameController = TextEditingController();
    final rateController = TextEditingController(text: '18.00');
    final regionsController = TextEditingController(text: 'All Domestic Zones');
    String selectedType = 'Exclusive';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: 480,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Tax Profile',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF181513),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF7A7268)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Define a new tax rate applicable to catalog items and delivery regions.',
                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF7A7268)),
                    ),
                    const SizedBox(height: 20),

                    // Tax Name
                    Text('Tax Name', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. GST 28% Luxury Fabric',
                        hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF9E958A)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFDFD4C5)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Rate & Type Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Rate (%)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: rateController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: GoogleFonts.inter(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: '18.00',
                                  suffixText: '%',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFDFD4C5)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Calculation Type', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFDFD4C5)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedType,
                                    isExpanded: true,
                                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF181513)),
                                    items: const [
                                      DropdownMenuItem(value: 'Exclusive', child: Text('Exclusive')),
                                      DropdownMenuItem(value: 'Inclusive', child: Text('Inclusive')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setDlgState(() => selectedType = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Regions Applied
                    Text('Regions Applied', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: regionsController,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Maharashtra, Karnataka or All Domestic',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFDFD4C5)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4C453C),
                            side: const BorderSide(color: Color(0xFFDECDB9)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Cancel', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            final name = nameController.text.trim();
                            final rate = double.tryParse(rateController.text.trim()) ?? 0.0;
                            final regions = regionsController.text.trim().isEmpty ? 'All Domestic Zones' : regionsController.text.trim();
                            if (name.isNotEmpty) {
                              setState(() {
                                _taxProfiles.add(
                                  TaxProfileItem(
                                    id: 'tax_${DateTime.now().millisecondsSinceEpoch}',
                                    name: name,
                                    rate: rate,
                                    type: selectedType,
                                    regionsApplied: regions,
                                    isActive: true,
                                  ),
                                );
                              });
                            }
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF261D15),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Save Profile', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesktopContentConstraint(
        verticalPadding: 20,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Subtitle
              Text(
                'Manage your default currency, display formats, tax profiles, and calculation rules.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6E665B),
                ),
              ),
              const SizedBox(height: 20),

              // Two-Column Grid: Left (Currency & Rules) + Right (Tax Profiles Table)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 920;
                  if (isWide) {
                    final leftWidth = constraints.maxWidth * 0.40;
                    final rightWidth = constraints.maxWidth - leftWidth - 24;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column
                        SizedBox(
                          width: leftWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDefaultCurrencyCard(),
                              const SizedBox(height: 20),
                              _buildCurrencyDisplayOptionsCard(),
                              const SizedBox(height: 20),
                              _buildTaxAssignmentRulesCard(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Right Column
                        SizedBox(
                          width: rightWidth,
                          child: _buildTaxProfilesCard(),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDefaultCurrencyCard(),
                        const SizedBox(height: 20),
                        _buildCurrencyDisplayOptionsCard(),
                        const SizedBox(height: 20),
                        _buildTaxProfilesCard(),
                        const SizedBox(height: 20),
                        _buildTaxAssignmentRulesCard(),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================================
  // CARD 1: DEFAULT CURRENCY
  // ========================================================
  Widget _buildDefaultCurrencyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE2D5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF4E8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.toll_outlined,
                  size: 20,
                  color: Color(0xFFBA8A55),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Default Currency',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Set the base currency for your workspace.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF7A7268),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Currency Dropdown
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDFD4C5)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCurrency,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF6E665B)),
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E1C1A),
                ),
                items: const [
                  DropdownMenuItem(value: 'INR', child: Text('INR (₹) - Indian Rupee')),
                  DropdownMenuItem(value: 'USD', child: Text('USD (\$) - US Dollar')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR (€) - Euro')),
                  DropdownMenuItem(value: 'GBP', child: Text('GBP (£) - British Pound')),
                  DropdownMenuItem(value: 'AED', child: Text('AED (د.إ) - UAE Dirham')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCurrency = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // FORMAT PREVIEW BOX
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF6F0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEDE4D7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FORMAT PREVIEW',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: const Color(0xFFA37038),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getFormattedPreview(),
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getFormattedWords(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF7A7268),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // CARD 2: CURRENCY DISPLAY OPTIONS
  // ========================================================
  Widget _buildCurrencyDisplayOptionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE2D5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF4E8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.price_change_outlined,
                    size: 20,
                    color: Color(0xFFBA8A55),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Currency Display Options',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Control how currency is displayed across the system.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7A7268),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Hairline divider
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1EAE0)),

          // Row 1: Symbol Position
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Symbol Position',
                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w500, color: const Color(0xFF1E1C1A)),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _symbolPosition,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF6E665B)),
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF1E1C1A)),
                    items: const [
                      DropdownMenuItem(value: 'prefix', child: Text('Prefix (₹100)')),
                      DropdownMenuItem(value: 'suffix', child: Text('Suffix (100₹)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _symbolPosition = val);
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF6F1EA)),

          // Row 2: Decimal Places
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Decimal Places',
                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w500, color: const Color(0xFF1E1C1A)),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _decimalPlaces,
                    icon: const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF6E665B)),
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF1E1C1A)),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('0 ')),
                      DropdownMenuItem(value: 2, child: Text('2 ')),
                      DropdownMenuItem(value: 3, child: Text('3 ')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _decimalPlaces = val);
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF6F1EA)),

          // Row 3: Thousands Separator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thousands Separator',
                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w500, color: const Color(0xFF1E1C1A)),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _thousandsSeparator,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF6E665B)),
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF1E1C1A)),
                    items: const [
                      DropdownMenuItem(value: 'comma', child: Text('Comma (,)')),
                      DropdownMenuItem(value: 'dot', child: Text('Dot (.)')),
                      DropdownMenuItem(value: 'space', child: Text('Space ( )')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _thousandsSeparator = val);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  // ========================================================
  // CARD 3: TAX ASSIGNMENT RULES
  // ========================================================
  Widget _buildTaxAssignmentRulesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE2D5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF4E8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 20,
                  color: Color(0xFFBA8A55),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tax Assignment Rules',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Define how tax calculations are applied across products, locations, and sales channels.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF7A7268),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Rule 1: Per Product Rule
          _buildRuleTile(
            title: 'Per Product Rule',
            subtitle: 'Category-specific tax overrides standard rates.',
            value: _perProductRule,
            onChanged: (val) => setState(() => _perProductRule = val),
          ),
          const SizedBox(height: 12),

          // Rule 2: Per Location Rule
          _buildRuleTile(
            title: 'Per Location Rule',
            subtitle: 'Tax rate defaults to supplier/warehouse address.',
            value: _perLocationRule,
            onChanged: (val) => setState(() => _perLocationRule = val),
          ),
          const SizedBox(height: 12),

          // Rule 3: Per Channel Rule
          _buildRuleTile(
            title: 'Per Channel Rule',
            subtitle: 'B2C online channels apply flat inclusive rates.',
            value: _perChannelRule,
            onChanged: (val) => setState(() => _perChannelRule = val),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEFE8DD)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF7A7268),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildPillToggle(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildPillToggle({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          width: 44,
          height: 24,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: value ? const Color(0xFF553519) : const Color(0xFFE2D9CC),
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
                    color: Color(0x2A000000),
                    blurRadius: 2.5,
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

  // ========================================================
  // CARD 4: TAX PROFILES (RIGHT COLUMN)
  // ========================================================
  Widget _buildTaxProfilesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE2D5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF4E8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.badge_outlined,
                        size: 20,
                        color: Color(0xFFBA8A55),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tax Profiles',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF181513),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Configure regional and category-level tax models.',
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
                ElevatedButton.icon(
                  onPressed: _showAddTaxProfileDialog,
                  icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  label: Text(
                    'Add Tax Profile',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF261D15),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
          ),

          // Hairline divider
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1EAE0)),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: const Color(0xFFFAF7F2),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Tax Name',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF7A7268)),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Rate',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF7A7268)),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Type',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF7A7268)),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Regions Applied',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF7A7268)),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Status',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF7A7268)),
                  ),
                ),
                const SizedBox(
                  width: 36,
                  child: Text(
                    'Actions',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF7A7268)),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF1EAE0)),

          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _taxProfiles.length,
            separatorBuilder: (ctx, index) => const Divider(height: 1, thickness: 1, color: Color(0xFFF6F1EA)),
            itemBuilder: (ctx, index) {
              final profile = _taxProfiles[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    // Tax Name
                    Expanded(
                      flex: 2,
                      child: Text(
                        profile.name,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181513),
                        ),
                      ),
                    ),

                    // Rate
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${profile.rate.toStringAsFixed(2)}%',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF4C453C),
                        ),
                      ),
                    ),

                    // Type
                    Expanded(
                      flex: 1,
                      child: Text(
                        profile.type,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF4C453C),
                        ),
                      ),
                    ),

                    // Regions Applied
                    Expanded(
                      flex: 3,
                      child: Text(
                        profile.regionsApplied,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6E665B),
                        ),
                      ),
                    ),

                    // Status Pill Badge
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: profile.isActive ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: profile.isActive ? const Color(0xFF2E7D32) : const Color(0xFF8E867B),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  profile.isActive ? 'Active' : 'Inactive',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: profile.isActive ? const Color(0xFF2E7D32) : const Color(0xFF8E867B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Actions More Icon Menu
                    SizedBox(
                      width: 36,
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz_rounded, size: 18, color: Color(0xFF7A7268)),
                        padding: EdgeInsets.zero,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text(
                              profile.isActive ? 'Deactivate' : 'Activate',
                              style: GoogleFonts.inter(fontSize: 12.5),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete Profile',
                              style: GoogleFonts.inter(fontSize: 12.5, color: Colors.red[700]),
                            ),
                          ),
                        ],
                        onSelected: (action) {
                          if (action == 'toggle') {
                            setState(() {
                              _taxProfiles[index] = profile.copyWith(isActive: !profile.isActive);
                            });
                          } else if (action == 'delete') {
                            setState(() {
                              _taxProfiles.removeAt(index);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF1EAE0)),

          // Bottom Callout Banner: "Need help with tax setup?"
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF3E7D3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 22,
                    color: Color(0xFFBA8A55),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need help with tax setup?',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF181513),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Configure tax rules based on your business type, locations, and product categories. You can also import tax settings from a template.',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6E665B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.menu_book_outlined, color: Color(0xFFBA8A55), size: 18),
                              const SizedBox(width: 10),
                              Text(
                                'Opening Atelier OS Tax & Fiscal Compliance Guide...',
                                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                              ),
                            ],
                          ),
                          backgroundColor: const Color(0xFF1E1C1A),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          duration: const Duration(milliseconds: 2000),
                        ),
                      );
                    },
                    icon: const Icon(Icons.menu_book_outlined, size: 15, color: Color(0xFF946A36)),
                    label: Text(
                      'View Documentation',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF946A36),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFFAF7F2),
                      side: const BorderSide(color: Color(0xFFDECDB9)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
