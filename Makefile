V=0.0.1
PKGTOOLVER ?= $(V)

PREFIX = /usr/local
MANDIR = $(PREFIX)/share/man
DATADIR = $(PREFIX)/share/pkgtool
BUILDDIR = build

rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

BINPROGS_SRC = $(wildcard src/*.in)
BINPROGS = $(addprefix $(BUILDDIR)/,$(patsubst src/%,bin/%,$(patsubst %.in,%,$(BINPROGS_SRC))))
LIBRARY_SRC = $(call rwildcard,src/lib,*.sh)
LIBRARY = $(addprefix $(BUILDDIR)/,$(patsubst src/%,%,$(patsubst %.in,%,$(LIBRARY_SRC))))
COMPLETIONS = $(addprefix $(BUILDDIR)/,$(patsubst %.in,%,$(wildcard contrib/completion/*/*)))
MANS = $(addprefix $(BUILDDIR)/,$(patsubst %.asciidoc,%,$(wildcard doc/man/*.asciidoc)))
DATA_FILES = $(wildcard data/*)

all: binprogs library completion man #data
binprogs: $(BINPROGS)
library: $(LIBRARY)
completion: $(COMPLETIONS)
man: $(MANS)

edit = sed \
	-e "s|@pkgdatadir[@]|$(DATADIR)|g" \
	-e "s|@pkgtoolver[@]|$(PKGTOOLVER)|g"
GEN_MSG = @echo "GEN $(patsubst $(BUILDDIR)/%,%,$@)"

define buildInScript
$(1)/%: $(2)%$(3)
	$$(GEN_MSG)
	@mkdir -p $$(dir $$@)
	@$(RM) "$$@"
	@cat $$< | $(edit) >$$@
	@chmod $(4) "$$@"
	@bash -O extglob -n "$$@"
endef

$(eval $(call buildInScript,build/bin,src/,.in,755))
$(eval $(call buildInScript,build/lib,src/lib/,,644))
$(foreach completion,$(wildcard contrib/completion/*),$(eval $(call buildInScript,build/$(completion),$(completion)/,.in,444)))

data:
	@install -d $(BUILDDIR)/data
	@cp -ra $(DATA_FILES) $(BUILDDIR)/data

clean:
	rm -rf $(BUILDDIR)

install: all
	install -dm0755 $(DESTDIR)$(PREFIX)/bin
	install -m0755 ${BINPROGS} $(DESTDIR)$(PREFIX)/bin
	install -dm0755 $(DESTDIR)$(DATADIR)/lib
	#install -dm0755 $(DESTDIR)$(DATADIR)/data
	cp -ra $(BUILDDIR)/lib/* $(DESTDIR)$(DATADIR)/lib
	#cp -ra $(BUILDDIR)/data -t $(DESTDIR)$(DATADIR)
	for manfile in $(MANS); do \
		install -Dm644 $$manfile -t $(DESTDIR)$(MANDIR)/man$${manfile##*.}; \
	done;

.PHONY: all binprogs library completion conf man data clean install uninstall tag dist upload test coverage check
.DELETE_ON_ERROR:
