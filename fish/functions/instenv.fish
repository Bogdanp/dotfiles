function instenv
  if test -e Pipfile
    pip install -U pip pipenv flake8 jedi rope importmagic autopep8 gnureadline
    pipenv install --dev
  else
    set reqs requirements.txt
    if test -e requirements-dev.txt
      set reqs requirements-dev.txt
    else if test -e requirements_dev.txt
      set reqs requirements_dev.txt
    else if test -e requirements/dev.txt
      set reqs requirements/dev.txt
    end

    pip install -U pip flake8 jedi rope importmagic autopep8 gnureadline -r $reqs
  end
end
