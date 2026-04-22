MATLAB_APP := /Applications/MATLAB_R2026a.app
MATLAB_BIN := $(MATLAB_APP)/bin/matlab
TMUX_SESSION := matlab-dev
MATLAB_FLAGS := -nodesktop

FILE ?= src/main.m
FUNC ?= src/main
TAIL_LINES ?= 200
RUN_START := ___MATLAB_RUN_START___
RUN_END := ___MATLAB_RUN_END___

.PHONY: matlab repl run run-func batch status matlab-kill

matlab:
	@if ! tmux has-session -t $(TMUX_SESSION) 2>/dev/null; then \
		tmux new-session -d -s $(TMUX_SESSION) 'cd "$(CURDIR)" && exec $(MATLAB_BIN) $(MATLAB_FLAGS)'; \
		echo "Started MATLAB tmux session: $(TMUX_SESSION)"; \
	else \
		:; \
	fi

repl: matlab
	@tmux attach-session -t $(TMUX_SESSION)

run: matlab
	@tmux send-keys -t $(TMUX_SESSION) "disp('$(RUN_START)')" Enter
	@tmux send-keys -t $(TMUX_SESSION) "cd('$(CURDIR)')" Enter
	@tmux send-keys -t $(TMUX_SESSION) "clearvars" Enter
	@tmux send-keys -t $(TMUX_SESSION) "clear functions" Enter
	@tmux send-keys -t $(TMUX_SESSION) "run('$(FILE)')" Enter
	@tmux send-keys -t $(TMUX_SESSION) "disp('$(RUN_END)')" Enter
	@i=0; \
	while ! tmux capture-pane -p -t $(TMUX_SESSION) | grep -q "$(RUN_END)"; do \
		i=$$((i+1)); \
		if [ $$i -ge 100 ]; then \
			echo "Timed out waiting for MATLAB output"; \
			exit 1; \
		fi; \
		sleep 0.05; \
	done
	@tmux capture-pane -p -t $(TMUX_SESSION) \
	| awk 'BEGIN{capture=0; buf=""} \
		/$(RUN_START)/{capture=1; buf=""; next} \
		/$(RUN_END)/{capture=0} \
		capture{buf = buf $$0 "\n"} \
		END{printf "%s", buf}' \
	| sed -E '/^>> (cd|clearvars|clear functions|run)/d' \
	| sed -E '/^>> *$$/d' \
	| sed '/^[[:space:]]*$$/d' \
	| tail -n $(TAIL_LINES)

run-func: matlab
	@tmux send-keys -t $(TMUX_SESSION) "disp('$(RUN_START)')" Enter
	@tmux send-keys -t $(TMUX_SESSION) "cd('$(CURDIR)')" Enter
	@tmux send-keys -t $(TMUX_SESSION) "clearvars" Enter
	@tmux send-keys -t $(TMUX_SESSION) "clear functions" Enter
	@tmux send-keys -t $(TMUX_SESSION) "$(FUNC)" Enter
	@tmux send-keys -t $(TMUX_SESSION) "disp('$(RUN_END)')" Enter
	@i=0; \
	while ! tmux capture-pane -p -t $(TMUX_SESSION) | grep -q "$(RUN_END)"; do \
		i=$$((i+1)); \
		if [ $$i -ge 100 ]; then \
			echo "Timed out waiting for MATLAB output"; \
			exit 1; \
		fi; \
		sleep 0.05; \
	done
	@tmux capture-pane -p -t $(TMUX_SESSION) \
	| awk 'BEGIN{capture=0; buf=""} \
		/$(RUN_START)/{capture=1; buf=""; next} \
		/$(RUN_END)/{capture=0} \
		capture{buf = buf $$0 "\n"} \
		END{printf "%s", buf}' \
	| sed -E '/^>> (cd|clearvars|clear functions)$$/d' \
	| sed -E '/^>> *$(FUNC)$$/d' \
	| sed -E '/^>> *$$/d' \
	| sed '/^[[:space:]]*$$/d' \
	| tail -n $(TAIL_LINES)

batch:
	@cd "$(CURDIR)" && $(MATLAB_BIN) -batch "run('$(FILE)')"

status:
	@tmux capture-pane -p -t $(TMUX_SESSION) | tail -n $(TAIL_LINES)

matlab-kill:
	@if tmux has-session -t $(TMUX_SESSION) 2>/dev/null; then \
		tmux kill-session -t $(TMUX_SESSION); \
		echo "Killed MATLAB session: $(TMUX_SESSION)"; \
	else \
		echo "No MATLAB session to kill"; \
	fi
