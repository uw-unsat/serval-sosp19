
Require Import Extraction.
Require Import ZArith.

Extraction Language Scheme.

Module Boolean.

  Axiom T : Set.
  Extract Constant T => "boolean?".

  Axiom from_bool : bool -> T.
  Extract Constant from_bool => "decode-boolean".

  Axiom from_bool_injective :
    forall x y, from_bool x = from_bool y -> x = y.
  Axiom from_bool_surjective :
    forall x, exists y, from_bool y = x.

  Axiom and : T -> T -> T.
  Extract Constant and => "boolean-and".
  Axiom and_coq : forall x y, and x y = from_bool true <->
                         (x = from_bool true /\ y = from_bool true).

  Axiom neg : T -> T.
  Extract Constant neg => "!".
  Axiom neg_coq : forall x, neg x = from_bool true <->
                       (x = from_bool false).

  Axiom or : T -> T -> T.
  Extract Constant or => "boolean-or".
  Axiom or_coq : forall x y, or x y = from_bool true <->
                        (x = from_bool true \/ y = from_bool true).

  Axiom Implies : T -> T -> T.
  Extract Constant Implies => "boolean-implies".
  Axiom implies_coq : forall x y, (Implies x y = from_bool true) <->
                             (x = from_bool true -> y = from_bool true).

  Axiom equal : T -> T -> T.
  Extract Constant equal => "boolean-equal".
  Axiom equal_coq : forall x y, equal x y = from_bool true <->
                           (x = from_bool true <-> y = from_bool true).

  Axiom ite : T -> T -> T -> T.
  Extract Constant ite => "boolean-ite".
  Axiom ite_coq_true : forall b x y, b = from_bool true ->
                                ite b x y = x.
  Axiom ite_coq_false : forall b x y, b = from_bool false ->
                                 ite b x y = y.

  Axiom Forall : (T -> T) -> T.
  Extract Constant Forall => "boolean-forall".
  Axiom Forall_coq :
    forall f,
      (Forall f) = from_bool true <->
      (forall x, f (from_bool x) = from_bool true).

End Boolean.

Module BV.

  Axiom T : nat -> Set.
  Extract Constant T => "#f". (* does not matter *)

  Axiom w64 : nat.
  Extract Constant w64 => "64".

  Axiom w32 : nat.
  Extract Constant w32 => "32".

  Axiom w16 : nat.
  Extract Constant w16 => "16".

  Axiom w8 : nat.
  Extract Constant w8 => "8".

  Axiom from_Z : forall (n: nat), Z -> T n.
  Extract Constant from_Z => "decode-bv".

  (* Comparison Operators *)

  Axiom eq : forall {n: nat}, T n -> T n -> Boolean.T.
  Extract Constant eq => "bveq-w".

  Axiom slt : forall {n: nat}, T n -> T n -> Boolean.T.
  Extract Constant slt => "bvslt-w".

  Axiom ult : forall {n: nat}, T n -> T n -> Boolean.T.
  Extract Constant ult => "bvult-w".

  Axiom sle : forall {n: nat}, T n -> T n -> Boolean.T.
  Extract Constant sle => "bvsle-w".

  Axiom ule : forall {n: nat}, T n -> T n -> Boolean.T.
  Extract Constant ule => "bvule-w".

  Axiom sgt : forall {n: nat}, T n -> T n -> Boolean.T.
  Extract Constant sgt => "bvsgt-w".

  Axiom ugt : forall {n: nat}, T n -> T n -> Boolean.T.
  Extract Constant ugt => "bvugt-w".

  Axiom sge : forall {n: nat}, T n -> T n -> Boolean.T.
  Extract Constant sge => "bvsge-w".

  Axiom uge : forall {n: nat}, T n -> T n -> Boolean.T.
  Extract Constant uge => "bvuge-w".

  (* Bitwise Operators *)

  Axiom not : forall {n: nat}, T n -> T n.
  Extract Constant not => "bvnot-w".

  Axiom and : forall {n: nat}, T n -> T n -> T n.
  Extract Constant and => "bvand-w".
  
  Axiom or : forall {n: nat}, T n -> T n -> T n.
  Extract Constant or => "bvor-w".

  Axiom xor : forall {n: nat}, T n -> T n -> T n.
  Extract Constant xor => "bvxor-w".

  Axiom shl : forall {n: nat}, T n -> T n -> T n.
  Extract Constant shl => "bvshl-w".

  Axiom lshr : forall {n: nat}, T n -> T n -> T n.
  Extract Constant lshr => "bvlshr-w".

  Axiom ashr : forall {n: nat}, T n -> T n -> T n.
  Extract Constant ashr => "bvashr-w".

  (* Arithmetic Operators *)
  
  Axiom neg : forall {n: nat}, T n -> T n.
  Extract Constant neg => "bvneg-w".

  Axiom add : forall {n: nat}, T n -> T n -> T n.
  Extract Constant add => "bvadd-w".
  
  Axiom sub : forall {n: nat}, T n -> T n -> T n.
  Extract Constant sub => "bvsub-w".

  Axiom mul : forall {n: nat}, T n -> T n -> T n.
  Extract Constant mul => "bvmul-w".
  
  Axiom sdiv : forall {n: nat}, T n -> T n -> T n.
  Extract Constant sdiv => "bvsdiv-w".

  Axiom udiv : forall {n: nat}, T n -> T n -> T n.
  Extract Constant udiv => "bvudiv-w".

  Axiom srem : forall {n: nat}, T n -> T n -> T n.
  Extract Constant srem => "bvsrem-w".

  Axiom urem : forall {n: nat}, T n -> T n -> T n.
  Extract Constant urem => "bvurem-w".

  Axiom smod : forall {n: nat}, T n -> T n -> T n.
  Extract Constant smod => "bvsmod-w".

End BV.

Module Integer.

  Axiom T : Set.
  Extract Constant T => "integer?".

  Axiom from_Z : Z -> T.
  Extract Constant from_Z => "decode-integer".

  Axiom to_Z_exists :
    exists (to_Z: T -> Z), (forall x, to_Z (from_Z x) = x) /\ (forall x, from_Z (to_Z x) = x).

  Theorem from_Z_injective :
    forall x y, from_Z x = from_Z y -> x = y.
  Proof.
    destruct to_Z_exists.
    destruct H.
    intros.
    eapply f_equal in H1.
    repeat rewrite H in H1; auto.
  Qed.

  Theorem from_Z_surjective :
    forall (x: T), exists (y: Z), from_Z y = x.
  Proof.
    intros.
    destruct to_Z_exists.
    destruct H.
    now exists (x0 x).
  Qed.

  Axiom add : T -> T -> T.

  Extract Constant add => "integer-add".
  Axiom add_coq : forall x y, add (from_Z x) (from_Z y) =
                         from_Z (x + y).

  Axiom sub : T -> T -> T.
  Extract Constant sub => "integer-sub".
  Axiom sub_coq : forall x y, sub (from_Z x) (from_Z y) =
                         from_Z (x - y).

  Axiom equal : T -> T -> Boolean.T.
  Extract Constant equal => "integer-equal".
  Axiom equal_coq : forall x y, equal x y = Boolean.from_bool true <-> (x = y).

  Axiom gt : T -> T -> Boolean.T.
  Extract Constant gt => "integer-gt".
  Axiom gt_coq : forall x y, gt (from_Z x) (from_Z y) =
                           Boolean.from_bool (Z.gtb x y).

  Axiom ite : Boolean.T -> T -> T -> T.
  Extract Constant ite => "integer-ite".
  Axiom ite_coq_true : forall b x y, b = Boolean.from_bool true ->
                                ite b x y = x.
  Axiom ite_coq_false : forall b x y, b = Boolean.from_bool false ->
                                 ite b x y = y.

  Axiom Forall : (T -> Boolean.T) -> (Boolean.T).
  Extract Constant Forall => "integer-forall".
  Axiom Forall_coq :
    forall f,
      (Forall f) = Boolean.from_bool true <->
      (forall (x: Z), f (from_Z x) = Boolean.from_bool true).

End Integer.

Inductive Proxy : Set -> Set :=
| Proxy_Integer : Proxy Integer.T
| Proxy_Boolean : Proxy Boolean.T
| Proxy_BV : forall n, Proxy (BV.T n).

Inductive theorem : Type :=
| proposition : Boolean.T -> theorem
| with_var : forall {T1: Set}, Proxy T1 ->
    (T1 -> theorem) -> theorem
| with_uf : forall {T1 T2: Set},
    Proxy T1 -> Proxy T2 ->
    ((T1 -> T2) -> theorem) -> theorem.

Fixpoint holds (t: theorem) : Prop :=
  match t with
  | proposition p => p = Boolean.from_bool true
  | @with_var T1 _ f => forall (x: T1), holds (f x)
  | @with_uf T1 T2 _ _ f => forall (g: T1 -> T2), holds (f g)
  end.

Inductive ty : Set := b | z.

Inductive Lang : ty -> Set :=
| Const_b : Boolean.T -> Lang b
| Equal_Z : Lang z -> Lang z -> Lang b
| Forall_Z : (Integer.T -> Lang b) -> Lang b
| Const_Z : Integer.T -> Lang z
| If_Z : Lang b -> Lang z -> Lang z -> Lang z.

Definition denote_rosette (t: ty) : Type :=
  match t with
  | b => Boolean.T | z => Integer.T
  end.

Fixpoint compile_rosette {t: ty} (l: Lang t) : denote_rosette t :=
  match l with
  | Forall_Z P => Integer.Forall (fun x => compile_rosette (P x))
  | Const_b x => x
  | Equal_Z x y => Integer.equal (compile_rosette x) (compile_rosette y) 
  | Const_Z x => x
  | If_Z c x y => Integer.ite (compile_rosette c) (compile_rosette x) (compile_rosette y)
  end.


Definition denote_coq (t: ty) : Type :=
  match t with
  | b => Prop | z => Z -> Prop
  end.

Fixpoint compile_coq {t: ty} (l: Lang t) : denote_coq t :=
  match l in Lang t return denote_coq t with
  | Forall_Z P => forall (x: Z), (compile_coq (P (Integer.from_Z x)))
  | Equal_Z x y => forall a, compile_coq x a <-> compile_coq y a
  | Const_b x => x = Boolean.from_bool true
  | Const_Z x => fun y => x = Integer.from_Z y
  | If_Z c x y => fun z => IF compile_coq c then compile_coq x z else compile_coq y z
  end.

Definition correct {t: ty} : Lang t -> Prop :=
  match t in ty return Lang t -> Prop with
  | b => fun l => compile_rosette l = Boolean.from_bool true <-> compile_coq l
  | z => fun l => forall x, compile_rosette l = Integer.from_Z x <-> compile_coq l x
  end.

Theorem compile_sound :
  forall t (l: Lang t),
    correct l.
Proof.
  intro.
  induction l; simpl; intros.
  - split; intros; auto.
  - split; intros.
    rewrite Integer.equal_coq in H.
    unfold correct in *.
    rewrite <- IHl1.
    rewrite <- IHl2.
    rewrite H.
    split; auto.

    rewrite Integer.equal_coq.
    unfold correct in *.
    destruct Integer.from_Z_surjective with (x := compile_rosette l2).
    rewrite <- H0.
    rewrite IHl1.
    apply H.
    apply IHl2; eauto.
  - split; intros.
    + rewrite Integer.Forall_coq in H0.
      unfold correct in *.
      apply H.
      auto.
    + apply Integer.Forall_coq.
      unfold correct in *.
      intros.
      rewrite H; auto.
  - split; intros; auto.
  - split; intros; unfold correct in *.
    + destruct IHl1.
      destruct (Boolean.from_bool_surjective) with (x := compile_rosette l1).
      destruct x0 eqn:?; subst.
      * unfold IF_then_else.
        left.
        split.
        apply H0.
        now rewrite <- H2.
        rewrite Integer.ite_coq_true in H.
        apply IHl2; auto.
        auto.
      * unfold IF_then_else.
        right.
        split.
        unfold not; intros.
        apply H1 in H3.
        rewrite <- H2 in H3.
        apply Boolean.from_bool_injective in H3.
        congruence.
        apply IHl3.
        rewrite Integer.ite_coq_false in H; auto.
    + destruct (Boolean.from_bool_surjective) with (x := compile_rosette l1).
      destruct x0 eqn:?; subst.
      * rewrite Integer.ite_coq_true; auto.
        apply IHl2.
        destruct H.
        destruct H; auto.
        destruct H.
        apply eq_sym in H0.
        apply IHl1 in H0.
        congruence.
      * rewrite Integer.ite_coq_false; auto.
        apply IHl3.
        destruct H.
        destruct H.
        rewrite <- IHl1 in H.
        rewrite H in H0.
        apply Boolean.from_bool_injective in H0.
        congruence.
        destruct H; auto.
Qed.


    