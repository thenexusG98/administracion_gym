import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:valhalla_bjj/core/theme/app_colors.dart';

class FightTimerPage extends StatefulWidget {
  const FightTimerPage({super.key});

  @override
  State<FightTimerPage> createState() => _FightTimerPageState();
}

class _FightTimerPageState extends State<FightTimerPage>
    with TickerProviderStateMixin {
  // ═══════════════════════════════════════════
  // CONFIGURACIÓN
  // ═══════════════════════════════════════════
  int _roundMinutes = 5;
  int _restSeconds = 30;
  int _totalRounds = 3;

  // ═══════════════════════════════════════════
  // ESTADO DEL TIMER
  // ═══════════════════════════════════════════
  int _currentRound = 1;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  bool _isResting = false;
  bool _isFinished = false;
  bool _isConfiguring = true;
  Timer? _timer;

  // Presets rápidos
  static const _roundPresets = [3, 5, 7, 10];
  static const _restPresets = [20, 30, 60, 90];
  static const _roundCountPresets = [1, 2, 3, 4, 5, 6, 8, 10];

  // Animación
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════
  // SONIDOS
  // ═══════════════════════════════════════════

  Future<void> _playSound(String fileName) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/$fileName'));
    } catch (e) {
      debugPrint('🔊 Error reproduciendo sonido: $e');
    }
  }

  void _playRoundEnd() => _playSound('round_end.wav');
  void _playRestEnd() => _playSound('rest_end.wav');
  void _playFightEnd() => _playSound('fight_end.wav');
  void _playCountdownTick() => _playSound('countdown_tick.wav');

  // ═══════════════════════════════════════════
  // LÓGICA DEL TIMER
  // ═══════════════════════════════════════════

  void _startTimer() {
    if (_isConfiguring) {
      _remainingSeconds = _roundMinutes * 60;
      _currentRound = 1;
      _isResting = false;
      _isFinished = false;
      _isConfiguring = false;
    }

    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void _tick(Timer timer) {
    if (_remainingSeconds > 0) {
      setState(() => _remainingSeconds--);

      // Últimos 10 segundos: pulso visual
      if (_remainingSeconds <= 10 && _remainingSeconds > 0) {
        _pulseController.forward().then((_) => _pulseController.reverse());
        // Tick audible en últimos 3 segundos
        if (_remainingSeconds <= 3) {
          HapticFeedback.mediumImpact();
          _playCountdownTick();
        }
      }
    } else {
      // Tiempo terminado
      HapticFeedback.heavyImpact();
      _timer?.cancel();

      if (_isResting) {
        // Terminó el descanso → siguiente ronda
        _playRestEnd();
        setState(() {
          _currentRound++;
          _isResting = false;
          _remainingSeconds = _roundMinutes * 60;
        });
        _timer = Timer.periodic(const Duration(seconds: 1), _tick);
      } else if (_currentRound < _totalRounds) {
        // Terminó la ronda → descanso
        _playRoundEnd();
        setState(() {
          _isResting = true;
          _remainingSeconds = _restSeconds;
        });
        _timer = Timer.periodic(const Duration(seconds: 1), _tick);
      } else {
        // ¡Terminaron todas las rondas!
        _playFightEnd();
        setState(() {
          _isRunning = false;
          _isFinished = true;
        });
        _pulseController.stop();
      }
    }
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
    _pulseController.stop();
  }

  void _resetTimer() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _isRunning = false;
      _isResting = false;
      _isFinished = false;
      _isConfiguring = true;
      _currentRound = 1;
      _remainingSeconds = 0;
    });
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress {
    final total = _isResting ? _restSeconds : _roundMinutes * 60;
    if (total == 0) return 0;
    return 1.0 - (_remainingSeconds / total);
  }

  // ═══════════════════════════════════════════
  // UI
  // ═══════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('⏱️ Timer de Combate'),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isRunning) {
              _showExitConfirmation();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _isConfiguring ? _buildConfigScreen() : _buildTimerScreen(),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Timer en curso'),
        content: const Text('¿Salir y detener el timer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetTimer();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // PANTALLA DE CONFIGURACIÓN
  // ═══════════════════════════════════════════

  Widget _buildConfigScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.red.withOpacity(0.15),
                    border: Border.all(color: AppColors.red.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(Icons.timer, color: AppColors.red, size: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  'Configura tu Combate',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ajusta rondas, tiempo y descanso',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Tiempo por ronda
          _buildSectionTitle('⏱️ Tiempo por ronda', '${_roundMinutes} min'),
          const SizedBox(height: 12),
          _buildChipSelector(
            options: _roundPresets,
            selected: _roundMinutes,
            suffix: 'min',
            onSelected: (val) => setState(() => _roundMinutes = val),
            color: AppColors.gold,
          ),

          const SizedBox(height: 28),

          // Número de rondas
          _buildSectionTitle('🥊 Número de rondas', '$_totalRounds rondas'),
          const SizedBox(height: 12),
          _buildChipSelector(
            options: _roundCountPresets,
            selected: _totalRounds,
            suffix: '',
            onSelected: (val) => setState(() => _totalRounds = val),
            color: AppColors.red,
          ),

          const SizedBox(height: 28),

          // Tiempo de descanso
          _buildSectionTitle('😮‍💨 Descanso entre rondas', '${_restSeconds}s'),
          const SizedBox(height: 12),
          _buildChipSelector(
            options: _restPresets,
            selected: _restSeconds,
            suffix: 's',
            onSelected: (val) => setState(() => _restSeconds = val),
            color: AppColors.info,
          ),

          const SizedBox(height: 16),

          // Slider para descanso personalizado
          Row(
            children: [
              const Text('10s', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _restSeconds.toDouble(),
                  min: 10,
                  max: 120,
                  divisions: 22,
                  activeColor: AppColors.info,
                  inactiveColor: AppColors.divider,
                  label: '${_restSeconds}s',
                  onChanged: (v) => setState(() => _restSeconds = v.round()),
                ),
              ),
              const Text('120s', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
            ],
          ),

          const SizedBox(height: 32),

          // Resumen
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                const Text(
                  'RESUMEN',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Rondas', '$_totalRounds'),
                    _buildSummaryItem('Pelea', '${_roundMinutes}min'),
                    _buildSummaryItem('Descanso', '${_restSeconds}s'),
                    _buildSummaryItem(
                      'Total',
                      _formatTime(
                        (_roundMinutes * 60 * _totalRounds) +
                            (_restSeconds * (_totalRounds - 1).clamp(0, 999)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Botón START
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _startTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 28),
                  SizedBox(width: 8),
                  Text(
                    '¡COMENZAR!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChipSelector({
    required List<int> options,
    required int selected,
    required String suffix,
    required ValueChanged<int> onSelected,
    required Color color,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: options.map((val) {
        final isSelected = val == selected;
        return GestureDetector(
          onTap: () => onSelected(val),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? color : AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)]
                  : null,
            ),
            child: Text(
              '$val$suffix',
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // PANTALLA DEL TIMER ACTIVO
  // ═══════════════════════════════════════════

  Widget _buildTimerScreen() {
    final timerColor = _isFinished
        ? AppColors.gold
        : _isResting
            ? AppColors.info
            : AppColors.red;

    final statusText = _isFinished
        ? '🏆 ¡COMBATE TERMINADO!'
        : _isResting
            ? '😮‍💨 DESCANSO'
            : '🥊 RONDA $_currentRound de $_totalRounds';

    return Column(
      children: [
        // Status bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: timerColor.withOpacity(0.15),
          child: Text(
            statusText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: timerColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 1,
            ),
          ),
        ),

        // Round indicators
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalRounds, (i) {
              final roundNum = i + 1;
              final isCompleted = roundNum < _currentRound;
              final isCurrent = roundNum == _currentRound && !_isFinished;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isCurrent ? 36 : 28,
                height: isCurrent ? 36 : 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppColors.success
                      : isCurrent
                          ? timerColor
                          : AppColors.cardDark,
                  border: Border.all(
                    color: isCurrent ? timerColor : AppColors.divider,
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '$roundNum',
                          style: TextStyle(
                            color: isCurrent
                                ? Colors.white
                                : AppColors.textHint,
                            fontWeight: FontWeight.bold,
                            fontSize: isCurrent ? 16 : 12,
                          ),
                        ),
                ),
              );
            }),
          ),
        ),

        // Timer principal
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circular progress + time
                ScaleTransition(
                  scale: _remainingSeconds <= 10 && _isRunning
                      ? _pulseAnimation
                      : const AlwaysStoppedAnimation(1.0),
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Fondo del círculo
                        SizedBox(
                          width: 260,
                          height: 260,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 8,
                            color: AppColors.divider,
                          ),
                        ),
                        // Progreso
                        SizedBox(
                          width: 260,
                          height: 260,
                          child: CircularProgressIndicator(
                            value: _isFinished ? 1.0 : _progress,
                            strokeWidth: 8,
                            color: timerColor,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        // Tiempo
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_isFinished)
                              Text(
                                _isResting ? 'DESCANSO' : 'RONDA $_currentRound',
                                style: TextStyle(
                                  color: timerColor.withOpacity(0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              _isFinished
                                  ? '¡FIN!'
                                  : _formatTime(_remainingSeconds),
                              style: TextStyle(
                                color: _remainingSeconds <= 10 && !_isResting && _isRunning
                                    ? AppColors.red
                                    : AppColors.textPrimary,
                                fontSize: _isFinished ? 48 : 64,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            if (!_isFinished)
                              Text(
                                _isResting
                                    ? 'Siguiente: Ronda ${_currentRound + 1}'
                                    : '$_roundMinutes:00 por ronda',
                                style: const TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Controles
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          child: _isFinished
              ? _buildFinishedControls()
              : _buildActiveControls(timerColor),
        ),
      ],
    );
  }

  Widget _buildActiveControls(Color timerColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Reset
        _buildControlButton(
          icon: Icons.stop_rounded,
          label: 'Reiniciar',
          color: AppColors.textHint,
          onPressed: _resetTimer,
        ),

        // Play / Pause (grande)
        GestureDetector(
          onTap: _isRunning ? _pauseTimer : _startTimer,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRunning ? AppColors.warning : timerColor,
              boxShadow: [
                BoxShadow(
                  color: (_isRunning ? AppColors.warning : timerColor)
                      .withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),

        // Skip (saltar descanso/ronda)
        _buildControlButton(
          icon: Icons.skip_next_rounded,
          label: 'Saltar',
          color: AppColors.textHint,
          onPressed: () {
            _timer?.cancel();
            setState(() => _remainingSeconds = 0);
            _tick(Timer(Duration.zero, () {}));
          },
        ),
      ],
    );
  }

  Widget _buildFinishedControls() {
    return Column(
      children: [
        // Resumen final
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Rondas', '$_totalRounds'),
              _buildSummaryItem('Tiempo/R', '${_roundMinutes}min'),
              _buildSummaryItem(
                'Total',
                _formatTime(
                  (_roundMinutes * 60 * _totalRounds) +
                      (_restSeconds * (_totalRounds - 1).clamp(0, 999)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Salir'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.divider),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _resetTimer,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Otra vez'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}
