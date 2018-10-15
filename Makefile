NAMES := regioes ufs regioes_intermediarias regioes_imediatas municipios
EXTENSIONS := csv json xlsx
TABELAS := $(foreach ext,$(EXTENSIONS),municipios.$(ext))
TABELAS_MIN := $(foreach ext,$(EXTENSIONS),$(foreach name,$(NAMES),min/$(name).$(ext)))


.PHONY: tabelas

tabelas: $(TABELAS) $(TABELAS_MIN)


.SECONDARY: .tabelas-sentinel

$(TABELAS) $(TABELAS_MIN): .tabelas-sentinel

.tabelas-sentinel: tabelas-municipios-brasileiros.ipynb
	poetry run jupyter nbconvert \
		--execute $< \
		--stdout > /dev/null


.PHONY: install lab clean

install:
	poetry install


lab:
	poetry run jupyter lab


clean:
	$(RM) $(TABELAS) $(TABELAS_MIN)
