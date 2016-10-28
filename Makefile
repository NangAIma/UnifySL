COQC = coqc

%.vo: %.v
	@echo COQC $*.v
	@$(COQC) -q -R "." -as Logic $*.v

all: Wf.vo base.vo IPC.vo trivial.vo Kripke.vo enumerate.vo LogicBase.vo SyntacticReduction.v \
     PropositionalLogic/Syntax.vo PropositionalLogic/ClassicalPropositionalLogic.vo \
     PropositionalLogic/TrivialSemantics.vo PropositionalLogic/Sound_Classical_Trivial.vo \
     PropositionalLogic/Complete_Classical_Trivial.vo lib/Coqlib.vo
