function instenv
  if test -e Pipfile
    pip install -U pip flake8 flake8-bugbear flake8-quotes isort jedi rope gnureadline
    pipenv install --dev
  else if test -e pyproject.toml
    pip install -U pip flake8 flake8-bugbear flake8-quotes isort jedi rope gnureadline
    poetry install
  else if test -e requirements.in
    pip-compile requirements.in
    pip-compile requirements-dev.in
    pip-sync requirements-dev.txt requirements.txt
  else
    set reqs requirements.txt
    if test -e requirements-dev.txt
      set reqs requirements-dev.txt
    else if test -e requirements_dev.txt
      set reqs requirements_dev.txt
    else if test -e requirements/dev.txt
      set reqs requirements/dev.txt
    end

    pip install -U pip flake8 flake8-bugbear flake8-quotes isort jedi rope gnureadline -r $reqs
  end
end
