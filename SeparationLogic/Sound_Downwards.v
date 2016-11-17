Require Import Coq.Logic.Classical_Prop.
Require Import Logic.lib.Coqlib.
Require Import Logic.MinimunLogic.LogicBase.
Require Import Logic.MinimunLogic.MinimunLogic.
Require Import Logic.PropositionalLogic.Syntax.
Require Import Logic.SeparationLogic.Syntax.
Require Import Logic.PropositionalLogic.KripkeSemantics.
Require Import Logic.SeparationLogic.DownwardsSemantics.
Require Import Logic.PropositionalLogic.IntuitionisticPropositionalLogic.
Require Import Logic.SeparationLogic.SeparationLogic.

Local Open Scope logic_base.
Local Open Scope PropositionalLogic.
Local Open Scope SeparationLogic.

Lemma sound_sepcon_comm {L: Language} {nL: NormalLanguage L} {pL: PropositionalLanguage L} {SL: SeparationLanguage L} {SM: Semantics L} {pkS: PreKripkeSemantics L SM} {kiSM: KripkeIntuitionisticSemantics L SM} {dsSM: DownwardsSemantics L SM}:
  forall x y: expr,
    forall M m,
      KRIPKE: M, m |= x * y --> y * x.
Proof.
  intros.
  rewrite sat_impp; intros.
  rewrite sat_sepcon in H0 |- *; intros.
  destruct H0 as [m1 [m2 [? [? ?]]]].
  exists m2, m1.
  split; [| split]; auto.
  apply join_comm; auto.
Qed.

Lemma sound_sepcon_assoc {L: Language} {nL: NormalLanguage L} {pL: PropositionalLanguage L} {sL: SeparationLanguage L} {SM: Semantics L} {pkS: PreKripkeSemantics L SM} {kiSM: KripkeIntuitionisticSemantics L SM} {dsSM: DownwardsSemantics L SM}:
  forall x y z: expr,
    forall M m,
      KRIPKE: M, m |= x * (y * z) <--> (x * y) * z.
Proof.
  intros.
  unfold iffp.
  rewrite sat_andp.
  split; intros.
  + rewrite sat_impp; intros.
    rewrite sat_sepcon in H0.
    destruct H0 as [mx [myz [? [? ?]]]].
    rewrite sat_sepcon in H2.
    destruct H2 as [my [mz [? [? ?]]]].
    apply join_comm in H0.
    apply join_comm in H2.
    destruct (join_assoc _ mz my mx myz n H2 H0) as [mxy [? ?]].
    apply join_comm in H5.
    apply join_comm in H6.
    rewrite sat_sepcon.
    exists mxy, mz.
    split; [| split]; auto.
    rewrite sat_sepcon.
    exists mx, my.
    split; [| split]; auto.
  + rewrite sat_impp; intros.
    rewrite sat_sepcon in H0.
    destruct H0 as [mxy [mz [? [? ?]]]].
    rewrite sat_sepcon in H1.
    destruct H1 as [mx [my [? [? ?]]]].
    destruct (join_assoc _ mx my mz mxy n H1 H0) as [myz [? ?]].
    rewrite sat_sepcon.
    exists mx, myz.
    split; [| split]; auto.
    rewrite sat_sepcon.
    exists my, mz.
    split; [| split]; auto.
Qed.

Lemma sound_wand_sepcon_adjoint {L: Language} {nL: NormalLanguage L} {pL: PropositionalLanguage L} {sL: SeparationLanguage L} {SM: Semantics L} {pkS: PreKripkeSemantics L SM} {kiSM: KripkeIntuitionisticSemantics L SM} {dsSM: DownwardsSemantics L SM}:
  forall x y z: expr,
    forall M,
     (forall m, KRIPKE: M, m |= x * y --> z) <-> (forall m, KRIPKE: M, m |= x --> (y -* z)).
Proof.
  intros.
  pose proof Korder_PreOrder M as H_PreOrder.
  split; intro.
  + assert (ASSU: forall m1 m2 m, join m1 m2 m -> KRIPKE: M, m1 |= x -> KRIPKE: M, m2 |= y -> KRIPKE: M, m |= z).
    Focus 1. {
      intros.
      specialize (H m).
      rewrite sat_impp in H.
      apply (H m); [reflexivity |].
      rewrite sat_sepcon.
      exists m1, m2; auto.
    } Unfocus.
    clear H.
    intros.
    rewrite sat_impp; intros.
    rewrite sat_wand; intros.
    apply (ASSU m0 m1 m2); auto.
    eapply sat_mono; eauto.
  + assert (ASSU: forall m0 m1 m2 m, Korder m0 m -> join m0 m1 m2 -> KRIPKE: M, m |= x -> KRIPKE: M, m1 |= y -> KRIPKE: M, m2 |= z).
    Focus 1. {
      intros.
      specialize (H m).
      rewrite sat_impp in H.
      revert m0 m1 m2 H0 H1 H3.
      rewrite <- sat_wand.
      apply (H m); [reflexivity | auto].
    } Unfocus.
    intros.
    rewrite sat_impp; intros.
    rewrite sat_sepcon in H1.
    destruct H1 as [m1 [m2 [? [? ?]]]].
    apply (ASSU m1 m2 n m1); auto.
    reflexivity.
Qed.

Lemma sound_sepcon_mono {L: Language} {nL: NormalLanguage L} {pL: PropositionalLanguage L} {sL: SeparationLanguage L} {SM: Semantics L} {pkS: PreKripkeSemantics L SM} {kiSM: KripkeIntuitionisticSemantics L SM} {dsSM: DownwardsSemantics L SM}:
  forall x1 x2 y1 y2: expr,
    forall M,
     (forall m, KRIPKE: M, m |= x1 --> x2) ->
     (forall m, KRIPKE: M, m |= y1 --> y2) ->
     (forall m, KRIPKE: M, m |= x1 * y1 --> x2 * y2).
Proof.
  intros.
  pose proof Korder_PreOrder M as H_PreOrder.
  assert (ASSUx: forall m, KRIPKE: M, m |= x1 -> KRIPKE: M, m |= x2).
  Focus 1. {
    intros.
    specialize (H m0).
    rewrite sat_impp in H.
    apply (H m0); [reflexivity | auto].
  } Unfocus.
  assert (ASSUy: forall m, KRIPKE: M, m |= y1 -> KRIPKE: M, m |= y2).
  Focus 1. {
    intros.
    specialize (H0 m0).
    rewrite sat_impp in H0.
    apply (H0 m0); [reflexivity | auto].
  } Unfocus.
  rewrite sat_impp; intros.
  rewrite sat_sepcon in H2 |- *.
  destruct H2 as [m1 [m2 [? [? ?]]]].
  exists m1, m2; auto.
Qed.

Lemma sound_sepcon_emp {L: Language} {nL: NormalLanguage L} {pL: PropositionalLanguage L} {sL: SeparationLanguage L} {uSL: UnitarySeparationLanguage L} {SM: Semantics L} {pkS: PreKripkeSemantics L SM} {kiSM: KripkeIntuitionisticSemantics L SM} {dsSM: DownwardsSemantics L SM} {UdsSM: UnitaryDownwardsSemantics L SM}:
  forall x: expr,
    forall M m, KRIPKE: M, m |= x * emp <--> x.
Proof.
  intros.
  pose proof Korder_PreOrder M as H_PreOrder.
  unfold iffp.
  rewrite sat_andp.
  split.
  + rewrite sat_impp; intros.
    rewrite sat_sepcon in H0.
    destruct H0 as [n' [u [? [? ?]]]].
    rewrite sat_emp in H2.
    assert (Korder u u) by reflexivity.
    specialize (H2 u H3).
    unfold unit in H2.
    apply join_comm in H0.
    specialize (H2 _ _ H0).
    eapply sat_mono; eauto.
  + rewrite sat_impp; intros.
    rewrite sat_sepcon.
    destruct (unit_exists M n) as [u [? ?]].
    exists n, u.
    split; [| split]; auto.
    - apply join_comm; auto.
    - rewrite sat_emp; auto.
Qed.

Lemma sound_sepcon_elim {L: Language} {nL: NormalLanguage L} {pL: PropositionalLanguage L} {sL: SeparationLanguage L} {uSL: UnitarySeparationLanguage L} {SM: Semantics L} {pkS: PreKripkeSemantics L SM} {kiSM: KripkeIntuitionisticSemantics L SM} {dsSM: DownwardsSemantics L SM}:
  forall x y: expr,
    forall M (join_as_Korder: forall M (m1 m2 m: Kworlds M), join m1 m2 m -> Korder m m1),
      forall m, KRIPKE: M, m |= x * y --> x.
Proof.
  intros.
  pose proof Korder_PreOrder M as H_PreOrder.
  rewrite sat_impp; intros.
  rewrite sat_sepcon in H0.
  destruct H0 as [m1 [m2 [? [? ?]]]].
  apply join_as_Korder in H0.
  eapply sat_mono; eauto.
Qed.
  