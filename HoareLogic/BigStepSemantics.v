Require Import Coq.Relations.Relation_Operators.
Require Import Logic.PropositionalLogic.KripkeSemantics.
Require Import Logic.SeparationLogic.SeparationAlgebra.
Require Import Logic.HoareLogic.ImperativeLanguage.
Require Import Logic.HoareLogic.ProgramState.

Class BigStepSemantics (P: ProgrammingLanguage) (state: Type): Type := {
  access: state -> cmd -> MetaState state -> Prop;
  access_defined: forall s c, exists ms, access s c ms
}.

Definition lift_access
          {P: ProgrammingLanguage}
          {state: Type}
          {BSS: BigStepSemantics P state}
          (ms1: MetaState state)
          (c: cmd)
          (ms2: MetaState state): Prop :=
  lift_relation (fun s => access s c) ms1 ms2.

Definition safe
           {P: ProgrammingLanguage}
           {state: Type}
           {BSS: BigStepSemantics P state}
           (s: state)
           (c: cmd):
  Prop :=
  ~ access s c Error.

Definition term_norm
           {P: ProgrammingLanguage}
           {state: Type}
           {BSS: BigStepSemantics P state}
           (s: state)
           (c: cmd):
  Prop :=
  ~ access s c Error /\ ~ access s c NonTerminating.

Class SABigStepSemantics (P: ProgrammingLanguage) (state: Type) {J: Join state} {kiM: KripkeIntuitionisticModel state} (BSS: BigStepSemantics P state): Type := {
  frame_property: forall m mf m' c n', join m mf m' -> access m' c n' -> exists n nf, Korder nf mf /\ lift_join n (Terminating nf) n' /\ access m c n
}.

Module ImpBigStepSemantics (D: DECREASE).

Export D.

Inductive loop_access_fin
          {state: Type}
          {kiM: KripkeIntuitionisticModel state}
          (R: state -> MetaState state -> Prop)
          (test: state -> Prop): state -> MetaState state -> Prop :=
| loop_access_Terminating:
    forall s1 ms2,
      ~ test s1 ->
      decrease (Terminating s1) ms2 ->
      loop_access_fin R test s1 ms2
| loop_access_abnormal:
    forall s1 ms2 ms3,
      test s1 ->
      decrease (Terminating s1) ms2 ->
      lift_relation R ms2 ms3 ->
      ms3 = Error \/ ms3 = NonTerminating ->
      loop_access_fin R test s1 ms3
| loop_access_step:
    forall s1 s2 s3 s4 ms,
      test s1 ->
      Korder s2 s1 ->
      R s2 (Terminating s3) ->
      Korder s4 s3 ->
      loop_access_fin R test s4 ms ->
      loop_access_fin R test s1 ms.

Inductive loop_access_inf
          {state: Type}
          {kiM: KripkeIntuitionisticModel state}
          (R: state -> MetaState state -> Prop)
          (test: state -> Prop): state -> Prop :=
| loop_access_inf_NonTerminating:
    forall (s1 s2 s3: nat -> state),
      (forall n, test (s1 n)) ->
      (forall n, Korder (s2 n) (s1 n)) ->
      (forall n, R (s2 n) (Terminating (s3 n))) ->
      (forall n, Korder (s1 (S n)) (s3 n)) ->
      loop_access_inf R test (s1 0).

Class ImpBigStepSemantics (P: ProgrammingLanguage) {iP: ImperativeProgrammingLanguage P} (state: Type) {kiM: KripkeIntuitionisticModel state} (BSS: BigStepSemantics P state): Type := {
  eval_bool: state -> bool_expr -> Prop;
  eval_bool_stable: forall b, Korder_stable (fun s => eval_bool s b);
  access_Ssequence: forall c1 c2 s ms,
    access s (Ssequence c1 c2) ms ->
    exists ms' ms'',
      access s c1 ms' /\ decrease ms' ms'' /\ lift_access ms'' c2 ms;
  access_Sifthenelse: forall b c1 c2 s ms,
    access s (Sifthenelse b c1 c2) ms ->
    (eval_bool s b /\ exists ms', decrease (Terminating s) ms' /\ lift_access ms' c1 ms) \/
    (~ eval_bool s b /\ exists ms', decrease (Terminating s) ms' /\ lift_access ms' c2 ms);
  access_Swhile: forall b c s ms,
    access s (Swhile b c) ms ->
    (loop_access_fin (fun s ms => access s c ms) (fun s => eval_bool s b) s ms) \/
    (loop_access_inf (fun s ms => access s c ms) (fun s => eval_bool s b) s /\ ms = NonTerminating)
}.

End ImpBigStepSemantics.

Module Total := ImpBigStepSemantics (ProgramState.Total).

Module Partial := ImpBigStepSemantics (ProgramState.Partial).

Instance Total2Partial_ImpBigStepSemantics {P: ProgrammingLanguage} {iP: ImperativeProgrammingLanguage P} (state: Type) {kiM: KripkeIntuitionisticModel state} {BSS: BigStepSemantics P state} (iBSS: Total.ImpBigStepSemantics P state BSS): Partial.ImpBigStepSemantics P state BSS.
Proof.
  refine (Partial.Build_ImpBigStepSemantics _ _ _ _ _ Total.eval_bool Total.eval_bool_stable _ _ _).
  + intros.
    pose proof Total.access_Ssequence c1 c2 s ms H
      as [ms' [ms'' [? [? ?]]]].
    exists ms', ms''; split; [| split]; auto.
    apply Total2Partial_decrease; auto.
  + intros.
    pose proof Total.access_Sifthenelse b c1 c2 s ms H
      as [[? [ms' [? ?]]] | [? [ms' [? ?]]]].
    - left; split; auto; exists ms'; split; auto.
      apply Total2Partial_decrease; auto.
    - right; split; auto; exists ms'; split; auto.
      apply Total2Partial_decrease; auto.
  + intros.
    pose proof Total.access_Swhile b c s ms H.
    destruct H0 as [? | [? ?]].
    - left.
      clear H; induction H0.
      * apply Partial.loop_access_Terminating; auto.
        apply Total2Partial_decrease; auto.
      * eapply Partial.loop_access_abnormal; eauto.
        apply Total2Partial_decrease; auto.
      * apply (Partial.loop_access_step _ _ s1 s2 s3 s4); eauto.
    - right; split; auto.
      clear ms H1 H.
      inversion H0; subst.
      econstructor; eauto.
Defined.
