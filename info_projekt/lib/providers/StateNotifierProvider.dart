import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:info_projekt/models/investment.dart';
import '../services/portfolio_service.dart';
import '../homepage_new.dart';

final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final portfolioServiceProvider =
    Provider<PortfolioService>((ref) => PortfolioService());

final investmentListProvider =
    FutureProvider.autoDispose<List<Investment>>((ref) async {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final uid = firebaseAuth.currentUser?.uid;

  if (uid == null) {
    throw Exception('User is not logged in');
  }

  final portfolioService = ref.watch(portfolioServiceProvider);
  final investments = await portfolioService.getIndividualInvestments(uid);
  return investments
      .map((investment) => Investment.fromMap(investment))
      .toList();
});

class InvestmentListNotifier extends StateNotifier<List<Investment>> {
  final PortfolioService portfolioService;
  final FirebaseAuth firebaseAuth;

  InvestmentListNotifier(this.portfolioService, this.firebaseAuth)
      : super(<Investment>[]);

  Future<void> refresh() async {
    print('Refresh method called');
    final uid = firebaseAuth.currentUser?.uid;

    if (uid == null) {
      throw Exception('User is not logged in');
    }

    final investments = await portfolioService.getIndividualInvestments(uid);
    print('Getting investments for user: $uid');
    state = investments
        .map((investment) => Investment.fromMap(investment))
        .toList();
    print('State updated: $state');
    print('UI rebuilt with investments: $investments');
  }
}

final investmentListNotifierProvider =
    StateNotifierProvider<InvestmentListNotifier, List<Investment>>((ref) {
  final portfolioService = ref.watch(portfolioServiceProvider);
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return InvestmentListNotifier(portfolioService, firebaseAuth);
});
