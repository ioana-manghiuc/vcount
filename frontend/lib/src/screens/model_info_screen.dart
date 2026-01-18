import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class ModelInfoScreen extends StatelessWidget {
  const ModelInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Choose the Right Model for Your Hardware'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModelCard(
              model: 'YOLO11n',
              speed: 'Fastest',
              accuracy: 'Good',
              hardwareReq: 'Minimal (suitable for edge devices, mobile, CPU)',
              description:
                  'The nano model is the smallest and fastest. Use this if you have limited hardware resources or need real-time processing on mobile or IoT devices.',
            ),
            const SizedBox(height: 16),
            _buildModelCard(
              model: 'YOLO11s',
              speed: 'Fast',
              accuracy: 'Better',
              hardwareReq: 'Low (suitable for CPU and older GPUs)',
              description:
                  'The small model offers a good balance between speed and accuracy. Recommended for laptops with limited GPU memory (2-4GB VRAM).',
            ),
            const SizedBox(height: 16),
            _buildModelCard(
              model: 'YOLO11m',
              speed: 'Medium',
              accuracy: 'Very Good',
              hardwareReq: 'Medium (suitable for modern GPUs)',
              description:
                  'The medium model is the most balanced option. Recommended for laptops with dedicated GPUs (4-6GB VRAM) or desktop computers.',
            ),
            const SizedBox(height: 16),
            _buildModelCard(
              model: 'YOLO11l',
              speed: 'Slow',
              accuracy: 'Excellent',
              hardwareReq: 'High (suitable for high-end GPUs)',
              description:
                  'The large model offers high accuracy with slower processing. Recommended for high-performance GPUs (8GB+ VRAM) or batch processing.',
            ),
            const SizedBox(height: 16),
            _buildModelCard(
              model: 'YOLO11xl',
              speed: 'Very Slow',
              accuracy: 'Outstanding',
              hardwareReq: 'Very High (suitable for premium hardware)',
              description:
                  'The extra-large model provides the best accuracy but requires significant computational resources. Recommended for high-end GPUs (12GB+ VRAM) or server environments.',
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 Recommendations:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Start with YOLO11n or YOLO11s if unsure about your hardware capabilities',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• If processing is too slow, downgrade to a smaller model',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• If accuracy is not good enough, upgrade to a larger model',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• GPU acceleration significantly improves speed (CUDA for NVIDIA, Metal for Apple)',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelCard({
    required String model,
    required String speed,
    required String accuracy,
    required String hardwareReq,
    required String description,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              model,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow('Speed:', speed),
                ),
                Expanded(
                  child: _buildInfoRow('Accuracy:', accuracy),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Hardware:', hardwareReq),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}
