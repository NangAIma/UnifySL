Require Import Coq.Relations.Relation_Operators.
Require Import Logic.lib.Stream.SigStream.
Require Import Logic.lib.Stream.StreamFunctions.
Require Import Logic.PropositionalLogic.KripkeSemantics.
Require Import Logic.SeparationLogic.SeparationAlgebra.
Require Import Logic.HoareLogic.ImperativeLanguage.
Require Import Logic.HoareLogic.ProgramState.
Require Import Logic.HoareLogic.Trace.

Class LocalTraceSemantics (P: ProgrammingLanguage) (state: Type): Type := {
  denote: cmd -> trace state -> Prop;
  trace_non_empty: forall c tr, denote c tr -> tr 0 <> None;
  trace_forward_legal: forall c tr n ms ms', denote c tr -> tr n = Some (ms, ms') -> ms <> NonTerminating /\ ms <> Error;
  trace_sequential: forall c tr, denote c tr -> sequential_trace tr
}.

Definition access {P: ProgrammingLanguage} {Imp: ImperativeProgrammingLanguage P} {state: Type} {LTS: LocalTraceSemantics P state} (s: state) (c: cmd) (ms: MetaState state) :=
  exists tr, denote c tr /\ begin_state tr (Terminating s) /\ end_state tr ms.

Class SALocalTraceSemantics (P: ProgrammingLanguage) (state: Type) {J: Join state} {kiM: KripkeIntuitionisticModel state} (LTS: LocalTraceSemantics P state): Type := {
  frame_property: forall c tr' m mf m',
    join m mf m' ->
    denote c tr' ->
    begin_state tr' (Terminating m') ->
    exists tr,
    denote c tr /\
    begin_state tr (Terminating m) /\
    (end_state tr Error \/
     exists trf,
       sequential_trace trf /\
       begin_state trf (Terminating mf) /\
       (forall k m' n',
         tr' k = Some (m', n') ->
         exists m n mf nf,
         tr k = Some (m, n) /\
         trf k = Some (mf, nf) /\
         lift_Korder nf mf /\
         lift_join n nf n'))
}.

Module ImpLocalTraceSemantics (D: DECREASE) (DT: DECREASE_TRACE with Module D := D).

Export D.
Export DT.

Class ImpLocalTraceSemantics (P: ProgrammingLanguage) {iP: ImperativeProgrammingLanguage P} (state: Type) {kiM: KripkeIntuitionisticModel state} (LTS: LocalTraceSemantics P state): Type := {
  eval_bool: state -> bool_expr -> Prop;
  eval_bool_stable: forall b, Korder_stable (fun s => eval_bool s b);
  denote_Ssequence: forall c1 c2 tr,
    denote (Ssequence c1 c2) tr ->
    traces_app (denote c1) (traces_app decrease_trace (denote c2)) tr;
  denote_Sifthenelse: forall b c1 c2 tr,
    denote (Sifthenelse b c1 c2) tr ->
    traces_app (decrease_trace_with_test (fun s => eval_bool s b)) (denote c1) tr \/
    traces_app (decrease_trace_with_test (fun s => ~ eval_bool s b)) (denote c2) tr;
  denote_Swhile: forall b c tr,
    denote (Swhile b c) tr ->
    traces_app (traces_pstar (traces_app (decrease_trace_with_test (fun s => eval_bool s b)) (denote c))) (decrease_trace_with_test (fun s => ~ eval_bool s b)) tr \/
    traces_pomega (traces_app (decrease_trace_with_test (fun s => eval_bool s b)) (denote c)) tr
}.

End ImpLocalTraceSemantics.

Module Total := ImpLocalTraceSemantics (ProgramState.Total) (Trace.Total).

Module Partial := ImpLocalTraceSemantics (ProgramState.Partial) (Trace.Partial).

Instance Total2Partial_ImpLocalTraceSemantics {P: ProgrammingLanguage} {iP: ImperativeProgrammingLanguage P} (state: Type) {kiM: KripkeIntuitionisticModel state} {LTS: LocalTraceSemantics P state} (iLTS: Total.ImpLocalTraceSemantics P state LTS): Partial.ImpLocalTraceSemantics P state LTS.
Proof.
  refine (Partial.Build_ImpLocalTraceSemantics _ _ _ _ _ Total.eval_bool Total.eval_bool_stable _ _ _).
  + intros.
    pose proof Total.denote_Ssequence c1 c2 tr H.
    clear H; revert tr H0.
    apply traces_app_mono; [hnf; intros; auto |].
    apply traces_app_mono; [| hnf; intros; auto].
    apply Total2Partial_decrease_trace.
  + intros.
    pose proof Total.denote_Sifthenelse b c1 c2 tr H as [ | ].
    - left.
      clear H; revert tr H0.
      apply traces_app_mono; [| hnf; intros; auto].
      apply Total2Partial_decrease_trace_with_test.
    - right.
      clear H; revert tr H0.
      apply traces_app_mono; [| hnf; intros; auto].
      apply Total2Partial_decrease_trace_with_test.
  + intros.
    pose proof Total.denote_Swhile b c tr H as [ | ].
    - left.
      clear H; revert tr H0.
      apply traces_app_mono.
      * apply traces_pstar_mono.
        apply traces_app_mono; [| hnf; intros; auto].
        apply Total2Partial_decrease_trace_with_test.
      * apply Total2Partial_decrease_trace_with_test.
    - right.
      clear H; revert tr H0.
      apply traces_pomega_mono.
      apply traces_app_mono; [| hnf; intros; auto].
      apply Total2Partial_decrease_trace_with_test.
Defined.