import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../providers/dio_provider.dart';
import '../providers/trackers_provider.dart';
import '../models/tracker.dart';
import '../pages/browser.page.dart';

class TrackerFormPage extends HookConsumerWidget {
  final Tracker? tracker;

  const TrackerFormPage({super.key, this.tracker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController(text: tracker?.name);
    final cronExprController =
        useTextEditingController(text: tracker?.cronExpr);
    final websiteUrlController =
        useTextEditingController(text: tracker?.websiteUrl);
    final selectorController =
        useTextEditingController(text: tracker?.selector);
    final compareModeValue = useState(tracker?.compareMode ?? 'innerText');
    final isSubmitLoading = useState(false);
    final isTestLoading = useState(false);

    final commonCronExpressions = {
      'Every 15 minutes': '*/15 * * * *',
      'Every hour': '0 * * * *',
      'Every day at 9 AM': '0 9 * * *',
      'Every Monday at 9 AM': '0 9 * * 1',
      'Every 1st of month': '0 0 1 * *',
    };

    Future<void> handleSubmit() async {
      if (!formKey.currentState!.validate()) return;

      try {
        isSubmitLoading.value = true;
        final dio = ref.read(dioProvider);

        final data = {
          'name': nameController.text,
          'cronExpr': cronExprController.text,
          'compareMode': compareModeValue.value,
          'websiteUrl': websiteUrlController.text,
          'selector': selectorController.text,
        };

        if (tracker != null) {
          await dio.put('/trackers/${tracker!.id}', data: data);
        } else {
          await dio.post('/trackers/', data: data);
        }

        if (context.mounted) {
          ref.invalidate(trackersProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tracker != null
                  ? 'Tracker updated successfully'
                  : 'Tracker created successfully'),
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        isSubmitLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tracker != null ? 'Edit Tracker' : 'Create Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter tracker name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                if (value.length > 255) {
                  return 'Name must be less than 255 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: TextFormField(
                    controller: cronExprController,
                    decoration: const InputDecoration(
                      labelText: 'Cron Expression',
                      hintText: 'Enter cron expression',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a cron expression';
                      }
                      if (value.length > 255) {
                        return 'Cron expression must be less than 255 characters';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: DropdownMenu<String>(
                    width: null,
                    label: const Text('Presets'),
                    dropdownMenuEntries:
                        commonCronExpressions.entries.map((entry) {
                      return DropdownMenuEntry<String>(
                        value: entry.value,
                        label: entry.key,
                      );
                    }).toList(),
                    onSelected: (String? value) {
                      if (value != null) {
                        cronExprController.text = value;
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: compareModeValue.value,
              decoration: const InputDecoration(
                labelText: 'Compare Mode',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'innerText',
                  child: Text('Inner Text'),
                ),
                DropdownMenuItem(
                  value: 'innerHtml',
                  child: Text('Inner HTML'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  compareModeValue.value = value;
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: websiteUrlController,
              decoration: InputDecoration(
                labelText: 'Website URL',
                hintText: 'Enter website URL',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.open_in_browser),
                  onPressed: () {
                    final url = websiteUrlController.text;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BrowserPage(
                          initialUrl: url,
                          onSelectorSelected: (url, selector) {
                            websiteUrlController.text = url;
                            selectorController.text = selector;
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a URL';
                }
                if (value.length > 2550) {
                  return 'URL must be less than 2550 characters';
                }
                try {
                  Uri.parse(value);
                  if (!value.startsWith('http://') &&
                      !value.startsWith('https://')) {
                    return 'Please enter a valid URL starting with http:// or https://';
                  }
                } catch (e) {
                  return 'Please enter a valid URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: selectorController,
              decoration: const InputDecoration(
                labelText: 'CSS Selector',
                hintText: 'Enter CSS selector',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a CSS selector';
                }
                if (value.length > 255) {
                  return 'Selector must be less than 255 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isSubmitLoading.value ? null : handleSubmit,
              child: isSubmitLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      tracker != null ? 'Update Tracker' : 'Create Tracker',
                    ),
            ),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, _) {
                return ElevatedButton(
                  onPressed: isTestLoading.value
                      ? null
                      : () async {
                          final isUrlValid = websiteUrlController
                                  .text.isNotEmpty &&
                              websiteUrlController.text.length <= 2550 &&
                              Uri.parse(websiteUrlController.text).isAbsolute &&
                              (websiteUrlController.text
                                      .startsWith('http://') ||
                                  websiteUrlController.text
                                      .startsWith('https://'));

                          final isSelectorValid =
                              selectorController.text.isNotEmpty &&
                                  selectorController.text.length <= 255;

                          if (!isUrlValid) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Please enter a valid website URL'),
                              ),
                            );
                            return;
                          }

                          if (!isSelectorValid) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Please enter a valid CSS selector'),
                              ),
                            );
                            return;
                          }

                          try {
                            isTestLoading.value = true;
                            final dio = ref.read(dioProvider);
                            final response = await dio.post(
                              '/trackers/test',
                              data: {
                                'websiteUrl': websiteUrlController.text,
                                'selector': selectorController.text,
                                'compareMode': compareModeValue.value,
                              },
                            );

                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                      'Test Result (${compareModeValue.value})'),
                                  content: SelectableText(
                                    response.data['result'] as String? ??
                                        'No result',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Error: ${e.toString()}')),
                              );
                            }
                          } finally {
                            isTestLoading.value = false;
                          }
                        },
                  child: isTestLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Test Selector'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
