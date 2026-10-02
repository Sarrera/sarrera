import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class CertificatesView extends StatefulWidget {
  const CertificatesView({super.key});

  @override
  State<CertificatesView> createState() => _CertificatesViewState();
}

class _CertificatesViewState extends State<CertificatesView> {
  int _selectedOption = 0;

  final List<Map<String, dynamic>> _options = [
    {
      'title': 'Internal CA (Active Default)',
      'desc': 'Local self-signed PKI managed automatically by Caddy. Perfect for air-gapped test labs and localhost.',
      'snippet': '''localhost {
    tls internal
    ...
}''',
    },
    {
      'title': 'Automated Public ACME (Let\'s Encrypt / ZeroSSL)',
      'desc': 'Zero-touch TLS certificate issuance with automatic 60-day renewals. Requires public HTTP-01 or TLS-ALPN-01 reachability.',
      'snippet': '''ai.yourcompany.com {
    tls security@yourcompany.com
    ...
}''',
    },
    {
      'title': 'Corporate Custom Wildcard PKI',
      'desc': 'Mount custom X.509 enterprise certificate bundles signed by your internal Root CA or Active Directory Certificate Services.',
      'snippet': '''ai.corp.internal {
    tls /etc/caddy/certs/bundle.pem /etc/caddy/certs/private.key
    ...
}''',
    },
    {
      'title': 'DNS-01 ACME Challenge',
      'desc': 'Issues valid public certificates for internal servers without exposing port 80 to the internet via Cloudflare / Route53 DNS API.',
      'snippet': '''ai.company.internal {
    tls {
        dns cloudflare {\$CLOUDFLARE_API_TOKEN}
    }
    ...
}''',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TLS Certificate Management & Security Perimeter',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Caddy terminates all incoming HTTPS connections, enforcing strict security headers (HSTS, nosniff, SAMEORIGIN).',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildSelectorList()),
                    const SizedBox(width: 24),
                    Expanded(flex: 3, child: _buildSnippetViewer()),
                  ],
                );
              }
              return Column(
                children: [
                  _buildSelectorList(),
                  const SizedBox(height: 24),
                  _buildSnippetViewer(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorList() {
    return Column(
      children: List.generate(_options.length, (i) {
        final opt = _options[i];
        final isSelected = _selectedOption == i;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => setState(() => _selectedOption = i),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary.withValues(alpha: 0.12) : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.surfaceBorder,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Radio<int>(
                    value: i,
                    groupValue: _selectedOption,
                    activeColor: AppTheme.primary,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedOption = val);
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(opt['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(opt['desc'], style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSnippetViewer() {
    final opt = _options[_selectedOption];
    final snippet = opt['snippet'] as String;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Caddyfile Snippet: ${opt['title']}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Snippet'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: snippet));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Caddyfile snippet copied!')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF030712),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Text(
                snippet,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: AppTheme.secondary),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'How to apply:\n1. Update config/Caddyfile with your preferred TLS directive.\n2. Reload Caddy configuration with: docker exec ai-caddy caddy reload --config /etc/caddy/Caddyfile',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
