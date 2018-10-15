NAMES := regioes ufs regioes_intermediarias regioes_imediatas municipios
EXTENSIONS := csv json xlsx
TABELAS := $(foreach ext,$(EXTENSIONS),municipios.$(ext))
TABELAS_MIN := $(foreach ext,$(EXTENSIONS),$(foreach name,$(NAMES),min/$(name).$(ext)))

TEMP_DIR := temp
RAW_MAP_FILES := $(foreach ext,shp cpg dbf prj shx,$(TEMP_DIR)/lim_municipio_a.$(ext))
RAW_MAP_FILES_ZIP := $(TEMP_DIR)/Limites_v2017.zip


.PHONY: maps

maps: municipios.topo.json

municipios.topo.json: $(filter %.shp,$(RAW_MAP_FILES)) $(filter %.csv,$(TABELAS))
	mapshaper -i $< snap \
		-rename-layers municipios \
		-rename-fields codigo_municipio=geocodigo \
		-filter-fields codigo_municipio \
		-simplify 1% -filter-islands min-area=1e8 \
		-join $(word 2,$^) keys=codigo_municipio,codigo_municipio \
		-o force format=topojson id-field=codigo_municipio $@

## Note: remove-empty will cause problemns when joining a table that expect all features
## Better to leave it there even empty
# mapshaper -i $< snap \
# 	-rename-layers municipios \
# 	-simplify 1% -filter-islands remove-empty min-area=1e8 \
# 	-o force format=topojson id-field=geocodigo $@


.SECONDARY: $(RAW_MAP_FILES) .raw-map-files-sentinel $(RAW_MAP_FILES_ZIP)

$(RAW_MAP_FILES): .raw-map-files-sentinel

.raw-map-files-sentinel: $(RAW_MAP_FILES_ZIP)
	unzip -o $^ $(notdir $(RAW_MAP_FILES)) -d $(TEMP_DIR)
	touch $(RAW_MAP_FILES)

$(RAW_MAP_FILES_ZIP):
	mkdir -p $(TEMP_DIR)
	wget -O $@ \
		'ftp://geoftp.ibge.gov.br/cartas_e_mapas/bases_cartograficas_continuas/bc250/versao2017/shapefile/Limites_v2017.zip'


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
