.PHONY: all ide programmer clean distclean validate

all: ide programmer

ide:
	$(MAKE) -C ide

programmer:
	$(MAKE) -C programmer

validate:
	$(MAKE) -C ide validate
	$(MAKE) -C programmer validate

clean:
	$(MAKE) -C ide clean
	$(MAKE) -C programmer clean

distclean:
	$(MAKE) -C ide distclean
	$(MAKE) -C programmer distclean
