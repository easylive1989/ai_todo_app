import 'package:flutter/material.dart';
import '../models/todo.dart';

class PrioritySelector extends StatelessWidget {
  final Priority selectedPriority;
  final Function(Priority) onPrioritySelected;

  const PrioritySelector({
    super.key,
    required this.selectedPriority,
    required this.onPrioritySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: Priority.values.map((priority) {
        final isSelected = priority == selectedPriority;
        final priorityInfo = _getPriorityInfo(priority);
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onPrioritySelected(priority),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? priorityInfo.color
                      : priorityInfo.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: priorityInfo.color,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      priorityInfo.icon,
                      color: isSelected 
                          ? Colors.white
                          : priorityInfo.color,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      priorityInfo.label,
                      style: TextStyle(
                        color: isSelected 
                            ? Colors.white
                            : priorityInfo.color,
                        fontWeight: isSelected 
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 2),
                      Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  PriorityInfo _getPriorityInfo(Priority priority) {
    switch (priority) {
      case Priority.low:
        return PriorityInfo(
          label: '低優先級',
          color: Colors.green,
          icon: Icons.keyboard_arrow_down,
        );
      case Priority.medium:
        return PriorityInfo(
          label: '中優先級',
          color: Colors.orange,
          icon: Icons.remove,
        );
      case Priority.high:
        return PriorityInfo(
          label: '高優先級',
          color: Colors.red,
          icon: Icons.keyboard_arrow_up,
        );
    }
  }
}

class PriorityInfo {
  final String label;
  final Color color;
  final IconData icon;

  PriorityInfo({
    required this.label,
    required this.color,
    required this.icon,
  });
}