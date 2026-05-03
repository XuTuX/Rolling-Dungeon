import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
import 'package:circle_war/game/auto_battle/engine/constants.dart';
import 'package:flutter/material.dart';

class SimulationSpeedControl extends StatelessWidget {
  final double speed;
  final ValueChanged<double> onChanged;
  final bool compact;

  const SimulationSpeedControl({
    super.key,
    required this.speed,
    required this.onChanged,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final fastEnabled = (speed - SIMULATION_FAST_SPEED).abs() < 0.01;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 11,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AutoBattlePalette.ink, width: 2.4),
        boxShadow: const [
          BoxShadow(
            color: AutoBattlePalette.ink,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 26 : 30,
            height: compact ? 26 : 30,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0A8),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: AutoBattlePalette.ink, width: 2),
            ),
            child: Icon(
              Icons.speed,
              size: compact ? 15 : 17,
              color: AutoBattlePalette.ink,
            ),
          ),
          SizedBox(width: compact ? 7 : 9),
          Expanded(
            child: Text(
              'SPEED',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AutoBattlePalette.ink,
                fontSize: compact ? 11 : 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _SpeedToggleButton(
            selected: fastEnabled,
            compact: compact,
            onTap: () => onChanged(
              fastEnabled ? SIMULATION_DEFAULT_SPEED : SIMULATION_FAST_SPEED,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedToggleButton extends StatelessWidget {
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _SpeedToggleButton({
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: selected ? '2배 속도 끄기' : '2배 속도',
      waitDuration: const Duration(milliseconds: 350),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: compact ? 48 : 56,
          height: compact ? 30 : 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                selected ? AutoBattlePalette.primary : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AutoBattlePalette.ink, width: 2),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: AutoBattlePalette.ink,
                      offset: Offset(2, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flash_on,
                size: compact ? 13 : 15,
                color: selected ? Colors.white : AutoBattlePalette.ink,
              ),
              const SizedBox(width: 2),
              Text(
                '2X',
                maxLines: 1,
                style: TextStyle(
                  color: selected ? Colors.white : AutoBattlePalette.ink,
                  fontSize: compact ? 11 : 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
