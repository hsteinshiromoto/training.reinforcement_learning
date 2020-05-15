#!/bin/bash

#!/bin/bash

## Test python environment is setup correctly
if [[ $1 = "test_environment" ]]; then
	echo ">>> Testing Python Environment"
	/usr/local/bin/test_environment.py
fi

## Install Python Dependencies
if [[ $1 = "requirements" ]]; then
 	echo ">>> Installing Required Modules .."
 	cd /usr/local/bin/
	python -m pip install -U pip setuptools wheel
	python -m pip install -r /usr/local/requirements.txt
	echo ">>> Done!"
fi

if [[ $1 = "jupyter_extensions" ]]; then
	echo ">>> Enabling Jupyter Notebook Extensions .."
	jupyter contrib nbextension install --system
	jupyter nbextensions_configurator enable --system
	jupyter nbextension enable contrib_nbextensions_help_item/main 
 	jupyter nbextension enable codefolding/main
 	jupyter nbextension enable code_prettify/code_prettify
 	jupyter nbextension enable collapsible_headings/main
 	jupyter nbextension enable comment-uncomment/main
 	jupyter nbextension enable equation-numbering/main
 	jupyter nbextension enable execute_time/ExecuteTime 
 	jupyter nbextension enable gist_it/main 
 	jupyter nbextension enable hide_input/main 
 	jupyter nbextension enable spellchecker/main
 	jupyter nbextension enable toc2/main
 	jupyter nbextension enable toggle_all_line_numbers/main
	echo ">>> Done!"
fi

## Make Dataset
if [[ $1 == "data" ]]; then
	bash run_python.sh requirements
	python src/data/make_dataset.py data/raw data/processed
fi

## Delete all compiled Python files
if [[ $1 = "clean" ]]; then
	find . -type f -name "*.py[co]" -delete
	find . -type d -name "__pycache__" -delete
fi

# ## Lint using flake8
# lint:
# 	flake8 src

## Upload Data to S3
if [[ $1 == "to_s3" ]]; then
	echo "Uploading data from data/ to S3"

	if [[ ${PROFILE_S3} == "default" ]]; then
		aws s3 sync data/ s3://${BUCKET}/data/
	else
		aws s3 sync data/ s3://${BUCKET}/data/ --profile ${PROFILE_S3}
	fi
elif [[ $1 == "from_s3" ]]; then
	echo "Downloaing data from data/ to S3"
	if [[ ${PROFILE_S3} == "default" ]]; then
		aws s3 sync s3://${BUCKET}/data/ data/
	else
		aws s3 sync s3://${BUCKET}/data/ data/ --profile ${PROFILE_S3}
	fi

fi

## Set up python interpreter environment
# Todo: test this!
if [[ $1 = "create_environment" ]]; then

	if [[ $(shell which conda) = True ]]; then
		@echo ">>> Detected conda, creating conda environment."
		conda create --name ${PROJECT_NAME} python=3
		@echo ">>> New conda env created. Activate with:\nsource activate ${PROJECT_NAME}"

	else
		python3 -m pip install -q virtualenv virtualenvwrapper
		@echo ">>> Installing virtualenvwrapper if not already intalled.\nMake sure the following lines are in shell startup file\n\
		export WORKON_HOME=$$HOME/.virtualenvs\nexport PROJECT_HOME=$$HOME/Devel\nsource /usr/local/bin/virtualenvwrapper.sh\n"
		@bash -c "source `which virtualenvwrapper.sh`;mkvirtualenv $(PROJECT_NAME) --python=$(PYTHON_INTERPRETER)"
		@echo ">>> New virtualenv created. Activate with:\nworkon $(PROJECT_NAME)"
	fi

fi
