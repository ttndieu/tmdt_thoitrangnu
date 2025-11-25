import 'package:flutter/material.dart';
import '../constants/app_color.dart';

class RatingBarWidget extends StatelessWidget {
  final int rating;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final Function(int)? onRatingChanged;
  final bool readOnly;

  const RatingBarWidget({
    Key? key,
    required this.rating,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
    this.onRatingChanged,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isFilled = starIndex <= rating;

        return GestureDetector(
          onTap: readOnly
              ? null
              : () {
                  if (onRatingChanged != null) {
                    onRatingChanged!(starIndex);
                  }
                },
          child: Icon(
            isFilled ? Icons.star : Icons.star_border,
            size: size,
            color: isFilled
                ? (activeColor ?? Colors.amber)
                : (inactiveColor ?? Colors.grey[300]),
          ),
        );
      }),
    );
  }
}

// ✅ RATING DISPLAY WITH AVERAGE
class RatingDisplay extends StatelessWidget {
  final double averageRating;
  final int reviewCount;
  final double starSize;
  final double fontSize;

  const RatingDisplay({
    Key? key,
    required this.averageRating,
    required this.reviewCount,
    this.starSize = 16,
    this.fontSize = 14,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          size: starSize,
          color: Colors.amber,
        ),
        const SizedBox(width: 4),
        Text(
          averageRating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($reviewCount)',
          style: TextStyle(
            fontSize: fontSize - 2,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ✅ INTERACTIVE RATING BAR WITH TEXT
class InteractiveRatingBar extends StatefulWidget {
  final int initialRating;
  final Function(int) onRatingChanged;

  const InteractiveRatingBar({
    Key? key,
    this.initialRating = 5,
    required this.onRatingChanged,
  }) : super(key: key);

  @override
  State<InteractiveRatingBar> createState() => _InteractiveRatingBarState();
}

class _InteractiveRatingBarState extends State<InteractiveRatingBar> {
  late int _currentRating;

  final Map<int, String> _ratingTexts = {
    1: 'Rất tệ',
    2: 'Tệ',
    3: 'Bình thường',
    4: 'Tốt',
    5: 'Rất tốt',
  };

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            final isFilled = starIndex <= _currentRating;

            return GestureDetector(
              onTap: () {
                setState(() => _currentRating = starIndex);
                widget.onRatingChanged(starIndex);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  isFilled ? Icons.star : Icons.star_border,
                  size: 48,
                  color: isFilled ? Colors.amber : Colors.grey[300],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Text(
          _ratingTexts[_currentRating] ?? '',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}