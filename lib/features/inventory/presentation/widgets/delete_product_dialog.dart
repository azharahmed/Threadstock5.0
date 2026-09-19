// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeleteProductDialog extends StatefulWidget {
  const DeleteProductDialog({
    super.key,
    this.productName = 'Nike Air Max 90',
    this.locationCount = 3,
    this.recordCount = 247,
    this.initialChecked = false,
    this.initialConfirmText = 'DELETE',
    this.onConfirmDelete,
  });

  final String productName;
  final int locationCount;
  final int recordCount;
  final bool initialChecked;
  final String initialConfirmText;
  final VoidCallback? onConfirmDelete;

  static Future<bool?> show(
    BuildContext context, {
    String productName = 'Nike Air Max 90',
    int locationCount = 3,
    int recordCount = 247,
    bool initialChecked = false,
    String initialConfirmText = 'DELETE',
    VoidCallback? onConfirmDelete,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) => DeleteProductDialog(
        productName: productName,
        locationCount: locationCount,
        recordCount: recordCount,
        initialChecked: initialChecked,
        initialConfirmText: initialConfirmText,
        onConfirmDelete: onConfirmDelete,
      ),
    );
  }

  @override
  State<DeleteProductDialog> createState() => _DeleteProductDialogState();
}

class _DeleteProductDialogState extends State<DeleteProductDialog> {
  late bool _isConfirmedChecked;
  late final TextEditingController _confirmTextController;

  @override
  void initState() {
    super.initState();
    _isConfirmedChecked = widget.initialChecked;
    _confirmTextController =
        TextEditingController(text: widget.initialConfirmText);
  }

  @override
  void dispose() {
    _confirmTextController.dispose();
    super.dispose();
  }

  bool get _isDeleteAllowed =>
      _isConfirmedChecked &&
      _confirmTextController.text.trim().toUpperCase() == 'DELETE';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 530,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8DFD3), width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x28000000),
                blurRadius: 36,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header: Warning Icon + Title / Subtitle + Close Button
                _buildHeader(),

                const SizedBox(height: 18),

                // 2. Warning Description Paragraph
                _buildWarningText(),

                const SizedBox(height: 16),

                // 3. Checkbox Confirmation Row
                _buildCheckboxRow(),

                const SizedBox(height: 18),

                // 4. "Type DELETE to confirm" Input Box
                _buildTypedConfirmation(),

                const SizedBox(height: 24),

                // 5. Actions Footer (Cancel & Delete Product)
                _buildActionsRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Red warning icon inside circular alert badge
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
          ),
          child: const Center(
            child: Icon(
              Icons.warning_amber_rounded,
              size: 22,
              color: Color(0xFFDC2626),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Title & Product Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delete Product',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.productName,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B6357),
                ),
              ),
            ],
          ),
        ),

        // Close button (X)
        InkWell(
          onTap: () => Navigator.of(context).pop(false),
          borderRadius: BorderRadius.circular(6),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.close_rounded,
              size: 20,
              color: Color(0xFF9E958A),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. WARNING DESCRIPTION
  // ---------------------------------------------------------------------------
  Widget _buildWarningText() {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF6B6357),
          height: 1.45,
        ),
        children: [
          const TextSpan(text: 'This will permanently remove '),
          TextSpan(
            text: widget.productName,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const TextSpan(text: ' and all associated inventory records across '),
          TextSpan(
            text: '${widget.locationCount}',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const TextSpan(text: ' locations. This action cannot be undone.'),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. CHECKBOX ROW
  // ---------------------------------------------------------------------------
  Widget _buildCheckboxRow() {
    return InkWell(
      onTap: () {
        setState(() {
          _isConfirmedChecked = !_isConfirmedChecked;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Custom Square Checkbox matching luxury aesthetic
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: _isConfirmedChecked
                    ? const Color(0xFF1E1B18)
                    : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _isConfirmedChecked
                      ? const Color(0xFF1E1B18)
                      : const Color(0xFFD1C7BA),
                  width: 1.4,
                ),
              ),
              child: _isConfirmedChecked
                  ? const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 10),

            // Checkbox Label
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF4A433A),
                  ),
                  children: [
                    const TextSpan(text: 'I understand this will delete '),
                    TextSpan(
                      text: '${widget.recordCount}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const TextSpan(text: ' inventory records'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. TYPED CONFIRMATION
  // ---------------------------------------------------------------------------
  Widget _buildTypedConfirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B6357),
            ),
            children: [
              const TextSpan(text: 'Type '),
              TextSpan(
                text: 'DELETE',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFDC2626),
                ),
              ),
              const TextSpan(text: ' to confirm'),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Red tinted input box
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFFCA5A5),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: _confirmTextController,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181513),
              letterSpacing: 0.3,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. ACTIONS ROW
  // ---------------------------------------------------------------------------
  Widget _buildActionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Cancel Button
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFDFD5C6)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181513),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Delete Product Button
        ElevatedButton.icon(
          onPressed: _isDeleteAllowed
              ? () {
                  Navigator.of(context).pop(true);
                  widget.onConfirmDelete?.call();
                }
              : null,
          icon: const Icon(
            Icons.delete_outline_rounded,
            size: 16,
            color: Colors.white,
          ),
          label: Text(
            'Delete Product',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            disabledBackgroundColor: const Color(0xFFFCA5A5),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
