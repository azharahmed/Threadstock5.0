import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleLocationMapView extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? placeName;
  final String? formattedAddress;
  final String? streetAddress;
  final String? city;
  final String? postalCode;
  final String? state;
  final String? country;
  final bool isVerified;
  final bool interactive;
  final ValueChanged<LatLng>? onCoordinatesChanged;

  const GoogleLocationMapView({
    super.key,
    this.latitude,
    this.longitude,
    this.placeName,
    this.formattedAddress,
    this.streetAddress,
    this.city,
    this.postalCode,
    this.state,
    this.country,
    this.isVerified = false,
    this.interactive = true,
    this.onCoordinatesChanged,
  });

  @override
  State<GoogleLocationMapView> createState() => _GoogleLocationMapViewState();
}

class _GoogleLocationMapViewState extends State<GoogleLocationMapView> {
  GoogleMapController? _mapController;

  bool get _hasCoordinates =>
      widget.latitude != null &&
      widget.longitude != null &&
      widget.latitude!.abs() <= 90 &&
      widget.longitude!.abs() <= 180;

  bool get _supportsNativeGoogleMap {
    if (kIsWeb) return true;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  @override
  void didUpdateWidget(covariant GoogleLocationMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hasCoordinates &&
        (oldWidget.latitude != widget.latitude ||
            oldWidget.longitude != widget.longitude)) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(widget.latitude!, widget.longitude!),
        ),
      );
    }
  }

  Future<void> _openExternalGoogleMaps() async {
    if (!_hasCoordinates) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[GoogleLocationMapView] Error launching Google Maps: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // If location is manual and has no coordinates, show "Address entered manually"
    if (!_hasCoordinates) {
      final hasManualDetails = (widget.placeName != null && widget.placeName!.trim().isNotEmpty) ||
          (widget.streetAddress != null && widget.streetAddress!.trim().isNotEmpty) ||
          (widget.city != null && widget.city!.trim().isNotEmpty);
      if (hasManualDetails) {
        return Container(
          key: const ValueKey('manual_address_indicator'),
          margin: const EdgeInsets.only(top: 18),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F6F0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5DACD)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.edit_location_alt_outlined,
                size: 18,
                color: Color(0xFF8C827A),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Address entered manually',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5E574E),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Container(
      key: const ValueKey('google_location_map_view'),
      margin: const EdgeInsets.only(top: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF9F4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5DACD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. REAL GOOGLE MAP AREA (Only shown when real coordinates exist)
          if (_hasCoordinates)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
              child: SizedBox(
                height: 190,
                width: double.infinity,
                child: Stack(
                  children: [
                    if (_supportsNativeGoogleMap)
                      GoogleMap(
                        key: const ValueKey('real_google_map'),
                        initialCameraPosition: CameraPosition(
                          target: LatLng(widget.latitude!, widget.longitude!),
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('location_pin'),
                            position: LatLng(widget.latitude!, widget.longitude!),
                            draggable: widget.interactive,
                            onDragEnd: (pos) =>
                                widget.onCoordinatesChanged?.call(pos),
                            infoWindow: InfoWindow(
                              title: widget.placeName ?? 'Location',
                              snippet: widget.formattedAddress,
                            ),
                          ),
                        },
                        onTap: widget.interactive
                            ? (pos) => widget.onCoordinatesChanged?.call(pos)
                            : null,
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        compassEnabled: false,
                        mapToolbarEnabled: false,
                        onMapCreated: (ctrl) => _mapController = ctrl,
                      )
                    else
                      // Desktop & headless fallback rendering real Google Maps representation
                      _buildDesktopGoogleMapRepresentation(),

                    // Floating Coordinates Badge
                    Positioned(
                      top: 10,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1C1A).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 13,
                              color: Color(0xFFE8D1A7),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${widget.latitude!.toStringAsFixed(4)}, ${widget.longitude!.toStringAsFixed(4)}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // "Open in Google Maps" External Link Button
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _openExternalGoogleMaps,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFDCCFBE),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Google Maps',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E1C1A),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 12,
                                  color: Color(0xFF7A7268),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 2. ADDRESS SUMMARY CONTENT (Requirement 11)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  widget.isVerified
                      ? Icons.check_circle_rounded
                      : Icons.edit_location_alt_rounded,
                  color: widget.isVerified
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF7A7268),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge (Verified location vs Manual address)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: widget.isVerified
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFEDE3D5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.isVerified
                                  ? '✓ Verified location'
                                  : 'Manual address',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: widget.isVerified
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFF6B6358),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Place Name / Location Name
                      Text(
                        widget.placeName?.isNotEmpty == true
                            ? widget.placeName!
                            : 'Location Name',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E1C1A),
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Formatted Address or Components
                      if (widget.formattedAddress?.isNotEmpty == true)
                        Text(
                          widget.formattedAddress!,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            height: 1.4,
                            color: const Color(0xFF5E574E),
                          ),
                        )
                      else ...[
                        if (widget.streetAddress?.isNotEmpty == true)
                          Text(
                            widget.streetAddress!,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: const Color(0xFF5E574E),
                            ),
                          ),
                        if (widget.city?.isNotEmpty == true ||
                            widget.postalCode?.isNotEmpty == true)
                          Text(
                            [
                              if (widget.city?.isNotEmpty == true) widget.city,
                              if (widget.postalCode?.isNotEmpty == true)
                                widget.postalCode,
                            ].join(' '),
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: const Color(0xFF5E574E),
                            ),
                          ),
                        if (widget.state?.isNotEmpty == true ||
                            widget.country?.isNotEmpty == true)
                          Text(
                            [
                              if (widget.state?.isNotEmpty == true) widget.state,
                              if (widget.country?.isNotEmpty == true)
                                widget.country,
                            ].join(', '),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF7A7268),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopGoogleMapRepresentation() {
    return Container(
      color: const Color(0xFFE8ECEF),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Styled Google Maps terrain background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE2E7EA),
                    Color(0xFFD4DDE2),
                    Color(0xFFE8ECEF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Central Google Pin
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFD32F2F),
                  size: 28,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  widget.placeName ?? 'Selected Location',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E1C1A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
