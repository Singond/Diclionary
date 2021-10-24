FROM ubuntu:18.04
# Install tools
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		build-essential \
		devscripts \
		debhelper \
		equivs \
		rsync \
		gpg \
		curl \
		libz-dev \
		ca-certificates
RUN echo 'deb http://download.opensuse.org/repositories/devel:/languages:/crystal/xUbuntu_18.04/ /' \
		| tee /etc/apt/sources.list.d/devel:languages:crystal.list \
	&& curl -fsSL https://download.opensuse.org/repositories/devel:languages:crystal/xUbuntu_18.04/Release.key \
		| gpg --dearmor \
		| tee /etc/apt/trusted.gpg.d/devel_languages_crystal.gpg > /dev/null \
	&& apt-get update && apt-get clean
COPY run-debuild /usr/bin/run-debuild
RUN chmod 755 /usr/bin/run-debuild
RUN mkdir /package-build
WORKDIR /package-build
ENTRYPOINT ["run-debuild"]
