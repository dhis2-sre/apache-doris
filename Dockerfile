# Apache Doris with the PostgreSQL JDBC driver already in place, so a JDBC catalog can reach a
# DHIS 2 database without fetching a driver at runtime. See README.md for why this image exists.
ARG tier=fe
ARG dorisVersion=2.1.11
ARG jdkVersion=17.0.19_10

# Jammy to match the Ubuntu 22.04 the Doris images are built on.
FROM eclipse-temurin:${jdkVersion}-jdk-jammy AS jdk

FROM apache/doris:${tier}-${dorisVersion}

# Repeated because the FROM above consumes the first declaration.
ARG tier
ARG jdbcVersion=42.7.5
ARG jdbcSha256=69020b3bd20984543e817393f2e6c01a890ef2e37a77dd11d6d8508181d079ab

# Doris loads drivers by file name from its own jdbc_drivers directory, so the name is stable and
# the version lives in the tag rather than in a path a catalog would have to spell out.
# 644 matches how Doris ships the jars in its own lib directory. The image runs as root today, so
# the default of 600 would work, but it would stop working the moment a security context sets a user.
ADD --chmod=644 --checksum=sha256:${jdbcSha256} \
    https://repo1.maven.org/maven2/org/postgresql/postgresql/${jdbcVersion}/postgresql-${jdbcVersion}.jar \
    /opt/apache-doris/${tier}/jdbc_drivers/postgresql.jar

# Doris bundles OpenJDK 17.0.2 from January 2022, which reads its cgroup controllers out of
# /proc/cgroups and then insists on finding a "memory" entry there. Kernels built without
# CONFIG_MEMCG_V1, which Linux 6.11 made possible and openSUSE MicroOS now ships, keep the memory
# controller in cgroup v2 only and so leave it out of that legacy list. The lookup returns null and
# the JVM dies initialising jdk.internal.platform, which takes BDB JE and the whole frontend with it.
# 17.0.19 takes whichever controller is present instead. Both tiers get it because both run a JVM.
#
# The bundled JDK stays where it is and only the symlink JAVA_HOME points at moves, so anything
# reaching for /usr/lib/jvm/jdk-17 by name still finds it.
COPY --from=jdk /opt/java/openjdk /usr/lib/jvm/temurin-17
RUN ln -sfn /usr/lib/jvm/temurin-17 /usr/lib/jvm/java && \
    java -version
