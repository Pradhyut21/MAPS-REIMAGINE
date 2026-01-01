import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wayfinder/theme.dart';
import 'package:wayfinder/services/voice_service.dart';
import 'package:wayfinder/services/alert_service.dart';
import 'package:wayfinder/services/location_service.dart';
import 'package:wayfinder/models/travel_alert.dart';
import 'package:wayfinder/screens/home_page.dart';
import 'package:wayfinder/nav.dart';
import 'package:wayfinder/widgets/app_background.dart';
import 'package:flutter/foundation.dart';
import 'package:wayfinder/openai/openai_config.dart';

class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({super.key});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final VoiceService _voiceService = VoiceService();
  final AlertService _alertService = AlertService();
  final LocationService _locationService = LocationService();
  final TextEditingController _commandController = TextEditingController();
  final OpenAIClient _ai = OpenAIClient(model: 'gpt-4o');
  
  List<TravelAlert> _alerts = [];
  bool _isListening = false;
  bool _isLoading = true;
  String _partialResult = '';
  double? _userLat;
  double? _userLon;
  bool _isSending = false;
  final List<_ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      _userLat = position.latitude;
      _userLon = position.longitude;
    } else {
      final defaultPos = LocationService.getDefaultPosition();
      _userLat = defaultPos.latitude;
      _userLon = defaultPos.longitude;
    }

    final alerts = await _alertService.getActiveAlerts('user1');
    
    setState(() {
      _alerts = alerts;
      _isLoading = false;
    });
  }

  Future<void> _startListening() async {
    final initialized = await _voiceService.initialize();
    if (!initialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice recognition not available'),
            backgroundColor: AppColors.emergencyRed,
          ),
        );
      }
      return;
    }

    setState(() => _isListening = true);
    
    await _voiceService.startListening(
      onResult: (result) {
        setState(() {
          _commandController.text = result;
          _partialResult = '';
          _isListening = false;
        });
      },
      onPartialResult: (result) {
        setState(() => _partialResult = result);
      },
    );
  }

  Future<void> _stopListening() async {
    await _voiceService.stopListening();
    setState(() => _isListening = false);
  }

  Future<void> _sendCommand() async {
    final command = _commandController.text.trim();
    if (command.isEmpty) return;
    setState(() {
      _isSending = true;
      _messages.add(_ChatMessage(role: _Role.user, content: command));
    });

    try {
      // Geofence command pattern: "alert me near <place> within <meters>"
      final lowerCommand = command.toLowerCase();
      final match = RegExp(r'near\s+(.+?)\s+within\s+(\d+)').firstMatch(lowerCommand);
      if (lowerCommand.contains('alert') && lowerCommand.contains('near') && match != null && _userLat != null && _userLon != null) {
        final placeName = match.group(1)!;
        final distance = int.tryParse(match.group(2)!) ?? 500;
        final alert = TravelAlert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: 'user1',
          placeName: placeName,
          latitude: _userLat!,
          longitude: _userLon!,
          radiusMeters: distance.toDouble(),
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _alertService.addAlert(alert);
        await _voiceService.speak('I will notify you when you are close to $placeName');
        _loadData();
        if (mounted) {
          setState(() {
            _messages.add(_ChatMessage(role: _Role.assistant, content: 'Done. I created an alert for "$placeName" within ${alert.radiusMeters.toInt()} meters. I\'ll notify you when you\'re nearby.'));
          });
        }
      } else {
        // General AI chat fallback using OpenAI
        debugPrint('AI: sending prompt');
        final reply = await _ai.chat(
          command,
          extraSystem: {
            'system_note': 'User context for better travel help',
            'coordinates': {'lat': _userLat, 'lon': _userLon},
            'alerts_active': _alerts.length,
          },
        );
        if (mounted) {
          setState(() {
            _messages.add(_ChatMessage(role: _Role.assistant, content: reply.isEmpty ? 'I couldn\'t find an answer.' : reply));
          });
        }
      }
    } catch (e) {
      debugPrint('Send failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI error: ${e.toString()}'), backgroundColor: AppColors.emergencyRed),
        );
        setState(() {
          _messages.add(_ChatMessage(role: _Role.assistant, content: 'Sorry, I couldn\'t process that just now.'));
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _commandController.clear();
      }
    }
  }

  Future<void> _clearAlerts() async {
    await _alertService.clearAllAlerts('user1');
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All alerts cleared'),
          backgroundColor: AppColors.golden,
        ),
      );
    }
  }

  @override
  void dispose() {
    _commandController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'AI Assistant',
          style: context.textStyles.titleLarge?.copyWith(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push(AppRoutes.voiceSettings),
            child: Text('Voice Settings', style: TextStyle(color: AppColors.golden)),
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            '${_alerts.length} active',
            style: context.textStyles.bodySmall?.copyWith(color: AppColors.lightGray),
          ),
          SizedBox(width: AppSpacing.md),
        ],
      ),
      body: AppGradientBackground(
        child: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.golden))
          : SingleChildScrollView(
              padding: AppSpacing.paddingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Travel alerts (geofence): get notified when you are near a place.',
                    style: context.textStyles.bodyMedium?.copyWith(color: AppColors.lightGray),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: AppColors.golden, size: 16),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        '${_userLat?.toStringAsFixed(4)}, ${_userLon?.toStringAsFixed(4)}',
                        style: context.textStyles.bodySmall?.copyWith(color: AppColors.lightGray),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xl),
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: AppColors.brownCard,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tell me: "alert me when I\'m near <place> within 500m". I will notify you when you are close.',
                          style: context.textStyles.bodyMedium?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl),
                  if (_messages.isNotEmpty) ...[
                    ..._messages.map((m) => _ChatBubble(message: m)).toList(),
                    SizedBox(height: AppSpacing.lg),
                  ],
                  
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.darkBrown,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: TextField(
                      controller: _commandController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Example: alert me near Majestic within 500m',
                        border: InputBorder.none,
                        hintStyle: context.textStyles.bodyMedium?.copyWith(color: AppColors.lightGray),
                      ),
                      style: context.textStyles.bodyMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                  if (_isListening && _partialResult.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: AppSpacing.paddingSm,
                      decoration: BoxDecoration(
                        color: AppColors.darkGolden.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        'Listening: $_partialResult',
                        style: context.textStyles.bodySmall?.copyWith(color: AppColors.golden),
                      ),
                    ),
                  ],
                  SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isListening ? _stopListening : _startListening,
                          icon: Icon(
                            _isListening ? Icons.stop : Icons.mic,
                            color: Colors.white,
                          ),
                          label: Text(
                            _isListening ? 'Stop' : 'Voice',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isListening ? AppColors.emergencyRed : AppColors.darkBrown,
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSending ? null : _sendCommand,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.golden,
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          child: _isSending
                              ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : Text('Send', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Alerts',
                        style: context.textStyles.titleMedium?.copyWith(color: AppColors.golden),
                      ),
                      if (_alerts.isNotEmpty)
                        TextButton.icon(
                          onPressed: _clearAlerts,
                          icon: Icon(Icons.delete, color: AppColors.emergencyRed, size: 16),
                          label: Text('Clear', style: TextStyle(color: AppColors.emergencyRed)),
                        ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),
                  _alerts.isEmpty
                      ? Container(
                          padding: AppSpacing.paddingMd,
                          decoration: BoxDecoration(
                            color: AppColors.brownCard,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Center(
                            child: Text(
                              'No alerts set.',
                              style: context.textStyles.bodyMedium?.copyWith(color: AppColors.lightGray),
                            ),
                          ),
                        )
                      : Column(
                          children: _alerts.map((alert) => AlertCard(
                            alert: alert,
                            onDelete: () async {
                              await _alertService.removeAlert(alert.id);
                              _loadData();
                            },
                          )).toList(),
                        ),
                ],
              ),
            ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 5),
    );
  }
}

class AlertCard extends StatelessWidget {
  final TravelAlert alert;
  final VoidCallback onDelete;

  const AlertCard({
    super.key,
    required this.alert,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.brownCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active, color: AppColors.golden),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.placeName,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Within ${alert.radiusMeters.toInt()}m',
                  style: context.textStyles.bodySmall?.copyWith(color: AppColors.lightGray),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: AppColors.emergencyRed),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

enum _Role { user, assistant }

class _ChatMessage {
  final _Role role;
  final String content;
  _ChatMessage({required this.role, required this.content});
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  const _ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == _Role.user;
    final bg = isUser ? AppColors.darkBrown : AppColors.brownCard;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = BorderRadius.only(
      topLeft: Radius.circular(AppRadius.md),
      topRight: Radius.circular(AppRadius.md),
      bottomLeft: Radius.circular(isUser ? AppRadius.md : AppRadius.sm),
      bottomRight: Radius.circular(isUser ? AppRadius.sm : AppRadius.md),
    );
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: 720),
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(color: bg, borderRadius: radius),
            child: SelectableText(
              message.content,
              style: context.textStyles.bodyMedium?.copyWith(color: Colors.white, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
