Require Import Rosette.
Require Import ZArith.
Require Import String.
Require Import List.

Open Scope string_scope.

Definition foo : Rosette.BV.T 4 := Rosette.BV.add (Rosette.BV.from_Z 4 8)
                                                  (Rosette.BV.from_Z 4 12).

Definition add_symmetry : Rosette.theorem :=
  Rosette.proposition (Rosette.Integer.Forall (fun x =>
    Rosette.Integer.Forall (fun y =>
      Rosette.Integer.equal (Rosette.Integer.add x y)
                            (Rosette.Integer.add y x)))).

Definition add_gt : Rosette.theorem :=
  Rosette.proposition (Rosette.Integer.Forall (fun x =>
    Rosette.Integer.Forall (fun y =>
      Rosette.Boolean.Implies 
        (Rosette.Integer.gt y (Rosette.Integer.from_Z 0))
        (Rosette.Integer.gt (Rosette.Integer.add x y) x)))).

Definition fx_is_fx : Rosette.theorem :=
  Rosette.with_uf Rosette.Proxy_Integer Rosette.Proxy_Integer (fun f =>
    Rosette.proposition (Rosette.Integer.Forall (fun x =>
      Rosette.Integer.equal (f x) (f x)))).

Definition fg_same_agree_on_four : Rosette.theorem :=
  with_uf Proxy_Integer Proxy_Integer (fun f =>
  with_uf Proxy_Integer Proxy_Integer (fun g =>
    proposition (Boolean.Implies
      (Integer.Forall (fun x => Integer.equal (f x) (g x)))
      (Integer.equal (f (Integer.from_Z 4)) (g (Integer.from_Z 4)))
  ))).

Open Scope Z_scope.

Definition one_crazy_bitvector : Rosette.theorem :=
  proposition (Boolean.neg (BV.eq (BV.from_Z BV.w64 0) (
   BV.not (
   BV.neg (
   BV.add (BV.from_Z BV.w64 2) (
   BV.sub (BV.from_Z BV.w64 2) (
   BV.mul (BV.from_Z BV.w64 2) (
   BV.sdiv (BV.from_Z BV.w64 2) (
   BV.udiv (BV.from_Z BV.w64 2) (
   BV.srem (BV.from_Z BV.w64 2) (
   BV.urem (BV.from_Z BV.w64 2) (
   BV.smod (BV.from_Z BV.w64 2) (
   BV.and (BV.from_Z BV.w64 2) (
   BV.or (BV.from_Z BV.w64 2) (
   BV.xor (BV.from_Z BV.w64 2) (
   BV.shl (BV.from_Z BV.w64 2) (
   BV.lshr (BV.from_Z BV.w64 2) (
   BV.ashr (BV.from_Z BV.w64 2) (
   BV.from_Z BV.w64 64))))))))))))))))))).


Definition bv4_is_bv4 : Rosette.theorem :=
  proposition (BV.eq (BV.from_Z BV.w8 4) (BV.from_Z BV.w8 4)).

Definition simple_ite : Rosette.theorem :=
  proposition (Integer.equal
                 (Integer.ite (Integer.equal (Integer.from_Z 8) (Integer.from_Z 12))
                              (Integer.from_Z 15) (Integer.from_Z 20))
                 (Integer.from_Z 20)).

Open Scope list_scope.


Definition update (f: Integer.T -> Integer.T)
                  (key: Integer.T)
                  (value: Integer.T) : Integer.T -> Integer.T :=
  fun key' => Integer.ite (Integer.equal key key') value (f key').


Definition functional_update_test : Rosette.theorem :=
  with_uf Proxy_Integer Proxy_Integer
          (fun f =>
             let f' := update f (Integer.from_Z 4) (Integer.from_Z 8)
             in proposition (Integer.equal (f' (Integer.from_Z 4)) (Integer.from_Z 8))).

Definition demorgan_1 : Rosette.theorem :=
  proposition (
   Boolean.Forall (fun a =>
    Boolean.Forall (fun b =>
                      Boolean.equal
                        (Boolean.neg (Boolean.and a b))
                        (Boolean.or (Boolean.neg a) (Boolean.neg b))))).


Definition pid_t := Integer.T.

Record State :=
  { value : pid_t -> Integer.T;
    level : pid_t -> Boolean.T;
    current : pid_t;
  }.

Definition Forall_State : (State -> theorem) -> theorem :=
  fun f => with_uf Proxy_Integer Proxy_Integer (fun value =>
        with_uf Proxy_Integer Proxy_Boolean (fun level =>
        with_var Proxy_Integer (fun current =>
          (f (Build_State value level current))))).


Inductive Action : Set :=
| get : Action
| get_level : Action
| raise : Action
| send : pid_t -> Integer.T -> Action. 

Definition Domain : Set := Integer.T.

Definition bool_to_int (b: Boolean.T) : Integer.T :=
  Integer.ite b (Integer.from_Z 1) (Integer.from_Z 0).

Definition step (s: State) (a: Action) : (State * Integer.T) :=
  match a with
  | get => (s, value s (current s))
  | get_level => (s, bool_to_int (level s (current s)))
  | raise =>
    ({|
        value := value s;
        level := fun y => Boolean.ite (Integer.equal y (current s))
                                   (Boolean.from_bool true)
                                   (level s y);
        current := current s;
     |}, Integer.from_Z 0)
  | _ => (s, Integer.from_Z 0)
  end.

Definition eqv (u: Domain) (s1 s2: State) : Boolean.T :=
  Boolean.from_bool true.

Definition weak_step_consistency (a: Action) : theorem :=
    Forall_State (fun st1 =>
    Forall_State (fun st2 =>
      with_var Proxy_Integer (fun d =>
                  proposition (Boolean.Implies
                      (eqv d st1 st2)
                      (eqv d (fst (step st1 a)) (fst (step st2 a))))))).

Definition local_respect (a: Action) : theorem :=
  Forall_State (fun st =>
    with_var Proxy_Integer (fun d =>
      proposition (eqv d st (fst (step st a))))).

Definition unwinding : list (Action -> theorem) :=
  weak_step_consistency ::
  local_respect ::
  nil.

Definition unfold_actions (f: Action -> theorem) : list theorem :=
  (with_var Proxy_Integer (fun recp =>
    with_var Proxy_Integer (fun val => f (send recp val)))) ::
  f raise ::
  f get ::
  f get_level :: nil.

Definition R_theorems : list Rosette.theorem :=
  add_symmetry ::
  add_gt ::
  fx_is_fx ::
  fg_same_agree_on_four ::
  bv4_is_bv4 ::
  one_crazy_bitvector ::
  simple_ite ::
  functional_update_test ::
  demorgan_1 ::
  weak_step_consistency get ::
  local_respect get ::
  nil ++

  flat_map unfold_actions unwinding.


Extraction "extracted.rkt" R_theorems foo.

Axiom R_verified :
  forall t, In t R_theorems ->
       holds t.

Ltac prove_from_rosette := (apply R_verified; unfold R_theorems; simpl; firstorder).

Lemma add_symmetry_verified :
  holds add_symmetry.
Proof. prove_from_rosette.
Qed.

Lemma add_gt_verified :
  holds add_gt.
Proof. prove_from_rosette.
Qed.

Lemma fx_is_fx_verified :
  holds fx_is_fx.
Proof. prove_from_rosette.
Qed.

Lemma fg_same_agree_on_four_verified :
  holds fg_same_agree_on_four.
Proof. prove_from_rosette.
Qed.

Lemma bv4_is_bv4_verified :
  holds bv4_is_bv4.
Proof. prove_from_rosette.
Qed.

Lemma one_crazy_bitvector_verified :
  holds one_crazy_bitvector.
Proof. prove_from_rosette.
Qed.

Lemma simple_ite_verified :
  holds simple_ite.
Proof. prove_from_rosette.
Qed.

Lemma functional_update_test_verified :
  holds functional_update_test.
Proof. prove_from_rosette.
Qed.

Lemma demorgan_1_verified :
  holds demorgan_1.
Proof. prove_from_rosette.
Qed.

Theorem fg_same_agree_on_four_hi :
  forall (f g: Z -> Z), (forall (x: Z), f x = g x) -> f 4 = g 4.
Proof.
  pose proof fg_same_agree_on_four_verified.
  unfold fg_same_agree_on_four in H.
  simpl in H.
  intros.
  pose proof Integer.to_Z_exists.
  destruct H1 as [to_Z [H1 H2]].
  specialize (H (fun x => Integer.from_Z (f (to_Z x)))).
  specialize (H (fun x => Integer.from_Z (g (to_Z x)))).
  simpl in H.
  rewrite Boolean.implies_coq in H.
  rewrite Integer.Forall_coq in H.
  repeat rewrite Integer.equal_coq in H.
  repeat rewrite H1 in H.
  apply Integer.from_Z_injective.
  apply H.
  intros.
  specialize (H0 x).
  repeat rewrite H1.
  rewrite Integer.equal_coq.
  rewrite H0.
  auto.
Qed.
