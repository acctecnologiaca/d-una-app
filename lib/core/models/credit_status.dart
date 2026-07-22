class CreditStatus {
  final int baseCredits;
  final int earnedCredits;
  final int reversedCredits;
  final int spentCredits;
  final int remainingCredits;
  final DateTime cycleStart;
  final DateTime cycleEnd;
  final bool isInitialThreeMonths;

  const CreditStatus({
    required this.baseCredits,
    required this.earnedCredits,
    required this.reversedCredits,
    required this.spentCredits,
    required this.remainingCredits,
    required this.cycleStart,
    required this.cycleEnd,
    required this.isInitialThreeMonths,
  });

  factory CreditStatus.fromJson(Map<String, dynamic> json) {
    return CreditStatus(
      baseCredits: json['baseCredits'] as int? ?? 0,
      earnedCredits: json['earnedCredits'] as int? ?? 0,
      reversedCredits: json['reversedCredits'] as int? ?? 0,
      spentCredits: json['spentCredits'] as int? ?? 0,
      remainingCredits: json['remainingCredits'] as int? ?? 0,
      cycleStart: DateTime.parse(json['cycleStart'] as String),
      cycleEnd: DateTime.parse(json['cycleEnd'] as String),
      isInitialThreeMonths: json['isInitialThreeMonths'] as bool? ?? false,
    );
  }
}
