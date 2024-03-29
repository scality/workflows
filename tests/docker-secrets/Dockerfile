FROM ubuntu

RUN --mount=type=secret,id=my_secret \
  cat /run/secrets/my_secret

RUN --mount=type=secret,id=my_other_secret \
  cat /run/secrets/my_other_secret

RUN apt-get update && apt-get install -y \
    git
