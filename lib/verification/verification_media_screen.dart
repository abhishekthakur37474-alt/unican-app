import 'dart:io';
import 'package:flutter/material.dart';
import '../models/verification_case.dart';
import '../services/location_service.dart';
import '../services/media_service.dart';
import '../services/verification_store.dart';
import 'verification_widgets.dart';
import 'verification_neighbor_screen.dart';
import 'verification_untraced_screen.dart';

class VerificationMediaScreen extends StatefulWidget {
  final VerificationCase verificationCase;

  const VerificationMediaScreen({super.key, required this.verificationCase});

  @override
  State<VerificationMediaScreen> createState() =>
      _VerificationMediaScreenState();
}

class _VerificationMediaScreenState extends State<VerificationMediaScreen> {
  final LocationService _locationService = LocationService();
  final MediaService _mediaService = MediaService();

  bool _locating = false;
  String? _locationError;

  VerificationCase get _case => widget.verificationCase;

  Future<void> _captureLocation() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });

    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        if (position != null) {
          _case.latitude = position.latitude;
          _case.longitude = position.longitude;
        } else {
          _locationError =
              'Location unavailable. Enable GPS and grant location permission.';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _locationError = 'Failed to get location.');
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _addPhoto({required bool fromCamera}) async {
    final file = fromCamera
        ? await _mediaService.capturePhoto()
        : await _mediaService.pickPhoto();
    if (file == null || !mounted) return;
    setState(() => _case.photoPaths.add(file.path));
  }

  void _removePhoto(int index) {
    setState(() => _case.photoPaths.removeAt(index));
  }

  void _next() {
    if (_case.latitude == null || _case.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capture the geo-tag first')),
      );
      return;
    }
    if (_case.photoPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attach at least one photo')),
      );
      return;
    }

    // Media captured: resume into the neighbor/untraced step.
    VerificationStore.instance.saveDraft(_case, _case.traced! ? 3 : 7);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _case.traced!
            ? VerificationNeighborScreen(verificationCase: _case)
            : VerificationUntracedScreen(verificationCase: _case),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return VStepScaffold(
      title: 'Geo Tag & Photos',
      onNext: _next,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _case.address,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Geo Tag',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  _case.latitude == null
                      ? Icons.location_off_outlined
                      : Icons.location_on_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _case.latitude == null
                        ? (_locationError ?? 'Location not captured')
                        : _case.geoTagText,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                if (_locating)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton(
                    onPressed: _captureLocation,
                    child: Text(_case.latitude == null ? 'Capture' : 'Refresh'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Photos',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addPhoto(fromCamera: true),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addPhoto(fromCamera: false),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_case.photoPaths.isEmpty)
            Text(
              'No photos attached yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (var i = 0; i < _case.photoPaths.length; i++)
                  Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_case.photoPaths[i]),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => _removePhoto(i),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black54,
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
