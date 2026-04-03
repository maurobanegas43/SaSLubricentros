import 'package:flutter/material.dart';
import 'loading_spinner.dart';

/// Example screen demonstrating LoadingSpinner usage
class LoadingSpinnerExample extends StatelessWidget {
  const LoadingSpinnerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LoadingSpinner Examples'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              'Spinner Variant',
              [
                _buildExample('Small', const LoadingSpinner(
                  size: LoadingSize.small,
                  variant: LoadingVariant.spinner,
                )),
                _buildExample('Medium', const LoadingSpinner(
                  size: LoadingSize.medium,
                  variant: LoadingVariant.spinner,
                )),
                _buildExample('Large', const LoadingSpinner(
                  size: LoadingSize.large,
                  variant: LoadingVariant.spinner,
                )),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              'Dots Variant',
              [
                _buildExample('Small', const LoadingSpinner(
                  size: LoadingSize.small,
                  variant: LoadingVariant.dots,
                )),
                _buildExample('Medium', const LoadingSpinner(
                  size: LoadingSize.medium,
                  variant: LoadingVariant.dots,
                )),
                _buildExample('Large', const LoadingSpinner(
                  size: LoadingSize.large,
                  variant: LoadingVariant.dots,
                )),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              'Bar Variant',
              [
                _buildExample('Small', const LoadingSpinner(
                  size: LoadingSize.small,
                  variant: LoadingVariant.bar,
                )),
                _buildExample('Medium', const LoadingSpinner(
                  size: LoadingSize.medium,
                  variant: LoadingVariant.bar,
                )),
                _buildExample('Large', const LoadingSpinner(
                  size: LoadingSize.large,
                  variant: LoadingVariant.bar,
                )),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              'With Messages',
              [
                _buildExample('Loading...', const LoadingSpinner(
                  message: 'Loading data...',
                )),
                _buildExample('Processing', const LoadingSpinner(
                  variant: LoadingVariant.dots,
                  message: 'Processing your request...',
                )),
                _buildExample('Please wait', const LoadingSpinner(
                  variant: LoadingVariant.bar,
                  message: 'Please wait...',
                )),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              'Custom Colors',
              [
                _buildExample('Blue', const LoadingSpinner(
                  color: Colors.blue,
                )),
                _buildExample('Green', const LoadingSpinner(
                  variant: LoadingVariant.dots,
                  color: Colors.green,
                )),
                _buildExample('Orange', const LoadingSpinner(
                  variant: LoadingVariant.bar,
                  color: Colors.orange,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> examples) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        ...examples,
      ],
    );
  }

  Widget _buildExample(String label, Widget spinner) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: spinner),
            ),
          ),
        ],
      ),
    );
  }
}
