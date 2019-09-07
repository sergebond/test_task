REBAR = rebar
DIALYZER = dialyzer
APP = test_task

DIALYZER_WARNINGS = -Wunmatched_returns -Werror_handling \
                    -Wrace_conditions -Wunderspecs

.PHONY: all compile test qc clean get-deps build-plt dialyze

all: deps

deps:
	@$(REBAR) get-deps
	@$(REBAR) compile

compile:
	@$(REBAR) compile

run:
	@$(REBAR) compile
	erl -pa ./ebin -pa ./deps/*/ebin -s $(APP) -config $(APP).sample

test: compile
	@$(REBAR) ct skip_deps=true

clean:
	@$(REBAR) clean

get-deps:
	@$(REBAR) get-deps

.dialyzer_plt:
	@$(DIALYZER) --build_plt --output_plt .dialyzer_plt \
	    --apps kernel stdlib

build-plt: .dialyzer_plt

dialyze: build-plt
	@$(DIALYZER) --src src --plt .dialyzer_plt $(DIALYZER_WARNINGS)