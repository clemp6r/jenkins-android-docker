### Proof of concept - not maintained

Docker image for running Android UI tests on emulators with Jenkins (work in progress).
It has been mainly created to run android emulators through KVM virtualization on x86 machines.
Running the container inside a virtual machine will also work but it will not benefit of KVM (i.e emulators will be slow).

Build the image:

    docker build -t="clemp6r/jenkinsandroid" .

Then create a container as following:

     docker run --privileged -t -i -p 8080:8080 clemp6r/jenkinsandroid


You can now connect to Jenkins on your container using port 8000, and create your jobs.

Caution: use the pre-installed 4.3 or 4.4 emulator images. The pre-installed 5.0 does not work correctly yet,
and installing other images through the android-emulator-plugin doesn't work neither.

Emulator options if KVM is available on the host machine:

    -noaudio -qemu -m 1024 -enable-kvm

Otherwise:

    -noaudio



