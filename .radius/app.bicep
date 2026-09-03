extension radius

@secure()
param browserlessToken string

@secure()
param encryptionSaltKeys string

param environment string

@secure()
param objectStorageSecretAccessKey string

@secure()
param postgresPassword string

@secure()
param posthogSecretKey string

param siteUrl string = 'http://localhost:8000'

var clickhouseHost = clickhouseContainer.properties.hosts.clickhouse
var kafkaHosts = '${kafkaContainer.properties.hosts.kafka}:9092'
var objectStorageEndpoint = 'http://${objectstorageContainer.properties.hosts.objectstorage}:19000'
var postgresDsn = 'postgres://myadmin:$POSTHOG_DB_PASSWORD@${postgresDb.properties.host}:5432/posthog?sslmode=require'
var redisHost = redisContainer.properties.hosts.redis
var redisUrl = 'redis://${redisHost}:6379/'
var seaweedfsEndpoint = 'http://${seaweedfsContainer.properties.hosts.seaweedfs}:8333'
var valkeyHost = valkeyContainer.properties.hosts.valkey

resource posthogApp 'Radius.Core/applications@2025-08-01-preview' = {
  name: 'posthog'
  properties: {
    environment: environment
  }
}

resource postgresDb 'Radius.Data/postgreSqlDatabases@2025-08-01-preview' = {
  name: 'posthog-postgres'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'posthog/settings/data_stores.py#L79'
    database: 'posthog'
    password: postgresPassword
    size: 'M'
    username: 'myadmin'
  }
}

resource clickhouseDataVolume 'Radius.Compute/persistentVolumes@2025-08-01-preview' = {
  name: 'clickhouse-data'
  properties: {
    environment: environment
    application: posthogApp.id
    allowedAccessModes: 'ReadWriteOnce'
    codeReference: 'docker-compose.hobby.yml#L734'
    sizeInGib: 100
  }
}

resource objectstorageDataVolume 'Radius.Compute/persistentVolumes@2025-08-01-preview' = {
  name: 'objectstorage-data'
  properties: {
    environment: environment
    application: posthogApp.id
    allowedAccessModes: 'ReadWriteOnce'
    codeReference: 'docker-compose.hobby.yml#L731'
    sizeInGib: 50
  }
}

resource redisDataVolume 'Radius.Compute/persistentVolumes@2025-08-01-preview' = {
  name: 'redis-data'
  properties: {
    environment: environment
    application: posthogApp.id
    allowedAccessModes: 'ReadWriteOnce'
    codeReference: 'docker-compose.hobby.yml#L737'
    sizeInGib: 10
  }
}

resource seaweedfsDataVolume 'Radius.Compute/persistentVolumes@2025-08-01-preview' = {
  name: 'seaweedfs-data'
  properties: {
    environment: environment
    application: posthogApp.id
    allowedAccessModes: 'ReadWriteOnce'
    codeReference: 'docker-compose.hobby.yml#L732'
    sizeInGib: 100
  }
}

resource zookeeperDataVolume 'Radius.Compute/persistentVolumes@2025-08-01-preview' = {
  name: 'zookeeper-data'
  properties: {
    environment: environment
    application: posthogApp.id
    allowedAccessModes: 'ReadWriteOnce'
    codeReference: 'docker-compose.hobby.yml#L728'
    sizeInGib: 10
  }
}

resource appSecrets 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'app-secrets'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'posthog/settings/access.py#L66'
    data: {
      BROWSERLESS_TOKEN: {
        value: browserlessToken
      }
      ENCRYPTION_SALT_KEYS: {
        value: encryptionSaltKeys
      }
      INTERNAL_API_SECRET: {
        value: posthogSecretKey
      }
      OBJECT_STORAGE_SECRET_ACCESS_KEY: {
        value: objectStorageSecretAccessKey
      }
      SECRET_KEY: {
        value: posthogSecretKey
      }
    }
  }
}

resource clickhouseConfig 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'clickhouse-config'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'docker/clickhouse/config.d/default.xml#L1'
    data: {
      'default.xml': {
        value: '<clickhouse>\n  <tcp_port>9000</tcp_port>\n  <remote_servers>\n    <posthog><shard><replica><host>localhost</host><port>9000</port></replica></shard></posthog>\n    <posthog_single_shard><shard><replica><host>localhost</host><port>9000</port></replica></shard></posthog_single_shard>\n    <posthog_migrations><shard><replica><host>localhost</host><port>9000</port></replica></shard></posthog_migrations>\n    <posthog_writable><shard><replica><host>localhost</host><port>9000</port></replica></shard></posthog_writable>\n    <posthog_primary_replica><shard><replica><host>localhost</host><port>9000</port></replica></shard></posthog_primary_replica>\n    <ai_events><shard><replica><host>localhost</host><port>9000</port></replica></shard></ai_events>\n    <aux><shard><replica><host>localhost</host><port>9000</port></replica></shard></aux>\n    <ops><shard><replica><host>localhost</host><port>9000</port></replica></shard></ops>\n    <sessions><shard><replica><host>localhost</host><port>9000</port></replica></shard></sessions>\n  </remote_servers>\n  <zookeeper>\n    <node><host>${zookeeperContainer.properties.hosts.zookeeper}</host><port>2181</port></node>\n  </zookeeper>\n  <named_collections>\n    <msk_cluster><kafka_broker_list from_env="KAFKA_HOSTS"/></msk_cluster>\n    <warpstream_ingestion><kafka_broker_list from_env="KAFKA_HOSTS"/></warpstream_ingestion>\n    <warpstream_calculated_events><kafka_broker_list from_env="KAFKA_HOSTS"/></warpstream_calculated_events>\n    <warpstream_replay><kafka_broker_list from_env="KAFKA_HOSTS"/></warpstream_replay>\n    <warpstream_shared><kafka_broker_list from_env="KAFKA_HOSTS"/></warpstream_shared>\n    <warpstream_cyclotron><kafka_broker_list from_env="KAFKA_HOSTS"/></warpstream_cyclotron>\n    <warpstream_logs><kafka_broker_list from_env="KAFKA_HOSTS"/></warpstream_logs>\n    <warpstream_traces><kafka_broker_list from_env="KAFKA_HOSTS"/></warpstream_traces>\n    <warpstream_metrics><kafka_broker_list from_env="KAFKA_HOSTS"/></warpstream_metrics>\n  </named_collections>\n  <macros>\n    <shard>01</shard>\n    <replica>ch1</replica>\n    <hostClusterType>online</hostClusterType>\n    <hostClusterRole>data</hostClusterRole>\n  </macros>\n</clickhouse>\n'
      }
    }
  }
}

resource livestreamConfig 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'livestream-config'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'docker/livestream/configs-hobby.yml#L1'
    data: {
      'configs.yml': {
        value: 'debug: false\nkafka:\n  brokers: "${kafkaHosts}"\n  topic: "events_plugin_ingestion"\n  group_id: "livestream"\n  security_protocol: "PLAINTEXT"\n  session_recording_enabled: true\n  session_recording_security_protocol: "PLAINTEXT"\nconsumers:\n  event:\n    enabled: true\n    brokers: "${kafkaHosts}"\n    topic: "events_plugin_ingestion"\n    security_protocol: "PLAINTEXT"\n    group_id: "livestream"\n  session_recording:\n    enabled: true\n    brokers: "${kafkaHosts}"\n    topic: "session_recording_snapshot_item_events"\n    security_protocol: "PLAINTEXT"\n    group_id: "livestream-session-recordings"\n  notification:\n    enabled: false\nmmdb:\n  path: "GeoLite2-City.mmdb"\n'
      }
    }
  }
}

resource postgresSecret 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'postgres-secret'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'posthog/settings/data_stores.py#L79'
    data: {
      password: {
        value: postgresPassword
      }
    }
  }
}

resource browserlessContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'browserless'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'posthog/settings/exports.py#L3'
    containers: {
      browserless: {
        image: 'ghcr.io/browserless/chromium:v2.51.2'
        env: {
          TOKEN: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'BROWSERLESS_TOKEN'
              }
            }
          }
        }
        ports: {
          web: {
            containerPort: 3000
          }
        }
      }
    }
  }
}

resource captureContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'capture'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'rust/capture/src/main.rs'
    containers: {
      capture: {
        image: 'ghcr.io/posthog/posthog/capture@sha256:89d816e0125632911001189fe3151cbee07a60f7b47997dc208f34978f03a476'
        env: {
          ADDRESS: {
            value: '0.0.0.0:3000'
          }
          CAPTURE_MODE: {
            value: 'events'
          }
          CAPTURE_V1_SINKS: {
            value: 'msk'
          }
          CAPTURE_V1_SINK_MSK_KAFKA_HOSTS: {
            value: kafkaHosts
          }
          CAPTURE_V1_SINK_MSK_KAFKA_TOPIC_CLIENT_INGESTION_WARNING: {
            value: 'ingestion-clientwarnings-main-1'
          }
          CAPTURE_V1_SINK_MSK_KAFKA_TOPIC_DLQ: {
            value: 'events_plugin_ingestion_dlq'
          }
          CAPTURE_V1_SINK_MSK_KAFKA_TOPIC_EXCEPTION: {
            value: 'ingestion-errortracking-main'
          }
          CAPTURE_V1_SINK_MSK_KAFKA_TOPIC_HEATMAP: {
            value: 'heatmaps_ingestion'
          }
          CAPTURE_V1_SINK_MSK_KAFKA_TOPIC_HISTORICAL: {
            value: 'events_plugin_ingestion_historical'
          }
          CAPTURE_V1_SINK_MSK_KAFKA_TOPIC_MAIN: {
            value: 'events_plugin_ingestion'
          }
          CAPTURE_V1_SINK_MSK_KAFKA_TOPIC_OVERFLOW: {
            value: 'events_plugin_ingestion_overflow'
          }
          KAFKA_ERROR_TRACKING_TOPIC: {
            value: 'ingestion-errortracking-main'
          }
          KAFKA_HOSTS: {
            value: kafkaHosts
          }
          KAFKA_TOPIC: {
            value: 'events_plugin_ingestion'
          }
          REDIS_URL: {
            value: redisUrl
          }
          RUST_LOG: {
            value: 'info,rdkafka=warn'
          }
        }
        ports: {
          web: {
            containerPort: 3000
          }
        }
      }
    }
  }
}

resource captureLogsContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'capture-logs'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'rust/capture-logs/src/main.rs'
    containers: {
      captureLogs: {
        image: 'ghcr.io/posthog/posthog/capture-logs@sha256:2c6bb87b74c88623d48bb6d235c5b5d383af82caffd3d3ff32bce168144f90ed'
        env: {
          BIND_HOST: {
            value: '0.0.0.0'
          }
          BIND_PORT: {
            value: '4318'
          }
          JWT_SECRET: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'SECRET_KEY'
              }
            }
          }
          KAFKA_HOSTS: {
            value: kafkaHosts
          }
          KAFKA_METRICS_TOPIC: {
            value: 'metrics_ingestion'
          }
          KAFKA_TOPIC: {
            value: 'logs_ingestion'
          }
          RUST_BACKTRACE: {
            value: '1'
          }
          RUST_LOG: {
            value: 'info,rdkafka=warn'
          }
        }
        ports: {
          web: {
            containerPort: 4318
          }
        }
      }
    }
  }
}

resource clickhouseContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'clickhouse'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'posthog/clickhouse/client/connection.py#L371'
    containers: {
      clickhouse: {
        image: 'clickhouse/clickhouse-server:26.6.2.158'
        env: {
          CLICKHOUSE_SKIP_USER_SETUP: {
            value: '1'
          }
          KAFKA_HOSTS: {
            value: kafkaHosts
          }
        }
        ports: {
          http: {
            containerPort: 8123
          }
          native: {
            containerPort: 9000
          }
        }
        volumeMounts: [
          {
            volumeName: 'config'
            mountPath: '/etc/clickhouse-server/config.d'
          }
          {
            volumeName: 'data'
            mountPath: '/var/lib/clickhouse'
          }
        ]
      }
    }
    volumes: {
      config: {
        secretName: clickhouseConfig.name
      }
      data: {
        persistentVolume: {
          accessMode: 'ReadWriteOnce'
          resourceId: clickhouseDataVolume.id
        }
      }
    }
  }
}

resource cymbalContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'cymbal'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'rust/cymbal/src/main.rs'
    containers: {
      cymbal: {
        image: 'ghcr.io/posthog/posthog/cymbal@sha256:5c542be55ddd114235c4ddc152ff407eaa699de0bb65255e4a0ab9220fb47644'
        command: [
          '/bin/sh'
          '-c'
          'export DATABASE_URL="${postgresDsn}"; export PERSONS_URL="$DATABASE_URL"; exec /usr/local/bin/cymbal'
        ]
        env: {
          BIND_HOST: {
            value: '0.0.0.0'
          }
          BIND_PORT: {
            value: '3302'
          }
          CYMBAL_REMOTE_RESOLUTION_HOST: {
            value: cymbalResolutionContainer.properties.hosts.cymbalResolution
          }
          INTERNAL_API_SECRET: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'INTERNAL_API_SECRET'
              }
            }
          }
          ISSUE_BUCKETS_REDIS_URL: {
            value: redisUrl
          }
          KAFKA_HOSTS: {
            value: kafkaHosts
          }
          OBJECT_STORAGE_ACCESS_KEY_ID: {
            value: 'any'
          }
          OBJECT_STORAGE_BUCKET: {
            value: 'posthog'
          }
          OBJECT_STORAGE_ENDPOINT: {
            value: seaweedfsEndpoint
          }
          OBJECT_STORAGE_FORCE_PATH_STYLE: {
            value: 'true'
          }
          OBJECT_STORAGE_SECRET_ACCESS_KEY: {
            value: 'any'
          }
          POSTHOG_DB_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: postgresSecret.name
                key: 'password'
              }
            }
          }
          REDIS_URL: {
            value: redisUrl
          }
          RUST_LOG: {
            value: 'info'
          }
        }
        ports: {
          web: {
            containerPort: 3302
          }
        }
      }
    }
  }
}

resource cymbalResolutionContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'cymbal-resolution'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'rust/cymbal/src/main.rs'
    containers: {
      cymbalResolution: {
        image: 'ghcr.io/posthog/posthog/cymbal@sha256:5c542be55ddd114235c4ddc152ff407eaa699de0bb65255e4a0ab9220fb47644'
        command: [
          '/bin/sh'
          '-c'
          'export DATABASE_URL="${postgresDsn}"; exec /usr/local/bin/cymbal'
        ]
        env: {
          CYMBAL_MODE: {
            value: 'resolution'
          }
          GRPC_ADDRESS: {
            value: '0.0.0.0:50061'
          }
          INTERNAL_API_SECRET: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'INTERNAL_API_SECRET'
              }
            }
          }
          OBJECT_STORAGE_ACCESS_KEY_ID: {
            value: 'any'
          }
          OBJECT_STORAGE_BUCKET: {
            value: 'posthog'
          }
          OBJECT_STORAGE_ENDPOINT: {
            value: seaweedfsEndpoint
          }
          OBJECT_STORAGE_FORCE_PATH_STYLE: {
            value: 'true'
          }
          OBJECT_STORAGE_SECRET_ACCESS_KEY: {
            value: 'any'
          }
          POSTHOG_DB_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: postgresSecret.name
                key: 'password'
              }
            }
          }
          RUST_LOG: {
            value: 'info'
          }
        }
        ports: {
          grpc: {
            containerPort: 50061
          }
        }
      }
    }
  }
}

resource featureFlagsContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'feature-flags'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'rust/feature-flags/src/main.rs'
    containers: {
      featureFlags: {
        image: 'ghcr.io/posthog/posthog/feature-flags@sha256:749dcfd23d7ba8c7125d4a9f3a9014e3744b2f02ad50463f9d04b591eca1bdea'
        command: [
          '/bin/sh'
          '-c'
          'export WRITE_DATABASE_URL="${postgresDsn}"; export READ_DATABASE_URL="$WRITE_DATABASE_URL"; export PERSONS_WRITE_DATABASE_URL="$WRITE_DATABASE_URL"; export PERSONS_READ_DATABASE_URL="$WRITE_DATABASE_URL"; exec /usr/local/bin/feature-flags'
        ]
        env: {
          ADDRESS: {
            value: '0.0.0.0:3001'
          }
          COOKIELESS_REDIS_HOST: {
            value: redisHost
          }
          COOKIELESS_REDIS_PORT: {
            value: '6379'
          }
          POSTHOG_DB_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: postgresSecret.name
                key: 'password'
              }
            }
          }
          REDIS_URL: {
            value: redisUrl
          }
          RUST_LOG: {
            value: 'info'
          }
        }
        ports: {
          web: {
            containerPort: 3001
          }
        }
        readinessProbe: {
          httpGet: {
            path: '/_readiness'
            port: 3001
          }
        }
      }
    }
  }
}

resource hypercacheServerContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'hypercache-server'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'rust/hypercache-server/src/main.rs'
    containers: {
      hypercacheServer: {
        image: 'ghcr.io/posthog/posthog/hypercache-server@sha256:738db2772f8e322a94e84762dbfe6cc55117a5003c184ddb189e29695c1ea2ee'
        env: {
          ADDRESS: {
            value: '0.0.0.0:3002'
          }
          REDIS_URL: {
            value: redisUrl
          }
          RUST_LOG: {
            value: 'info'
          }
        }
        ports: {
          web: {
            containerPort: 3002
          }
        }
        readinessProbe: {
          httpGet: {
            path: '/_readiness'
            port: 3002
          }
        }
      }
    }
  }
}

resource ingestionErrorTrackingContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'ingestion-error-tracking'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'nodejs/src/index.ts'
    containers: {
      ingestionErrorTracking: {
        image: 'docker.io/posthog/posthog-node@sha256:863e76e040ad41aef79f605c33ec71f1529bddf94cfd88941c935da9bde97235'
        args: [
          '/bin/sh'
          '-c'
          'export DATABASE_URL="${postgresDsn}"; exec node nodejs/dist/index.js'
        ]
        env: {
          CDP_REDIS_HOST: {
            value: redisHost
          }
          ENCRYPTION_SALT_KEYS: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'ENCRYPTION_SALT_KEYS'
              }
            }
          }
          ERROR_TRACKING_CYMBAL_BASE_URL: {
            value: 'http://${cymbalContainer.properties.hosts.cymbal}:3302'
          }
          KAFKA_HOSTS: {
            value: kafkaHosts
          }
          PLUGIN_SERVER_MODE: {
            value: 'ingestion-errortracking'
          }
          POSTHOG_DB_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: postgresSecret.name
                key: 'password'
              }
            }
          }
          REDIS_URL: {
            value: redisUrl
          }
        }
      }
    }
  }
}

resource ingestionGeneralContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'ingestion-general'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'nodejs/src/index.ts'
    containers: {
      ingestionGeneral: {
        image: 'docker.io/posthog/posthog-node@sha256:863e76e040ad41aef79f605c33ec71f1529bddf94cfd88941c935da9bde97235'
        args: [
          '/bin/sh'
          '-c'
          'export DATABASE_URL="${postgresDsn}"; export PERSONS_DATABASE_URL="$DATABASE_URL"; export BEHAVIORAL_COHORTS_DATABASE_URL="$DATABASE_URL"; exec node nodejs/dist/index.js'
        ]
        env: {
          AI_BLOB_OFFLOAD_TEAMS: {
            value: '*'
          }
          AI_BLOB_S3_ACCESS_KEY_ID: {
            value: 'object_storage_root_user'
          }
          AI_BLOB_S3_BUCKET: {
            value: 'ai-blobs'
          }
          AI_BLOB_S3_ENDPOINT: {
            value: objectStorageEndpoint
          }
          AI_BLOB_S3_PREFIX: {
            value: 'aio/'
          }
          AI_BLOB_S3_REGION: {
            value: 'us-east-1'
          }
          AI_BLOB_S3_SECRET_ACCESS_KEY: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'OBJECT_STORAGE_SECRET_ACCESS_KEY'
              }
            }
          }
          CDP_REDIS_HOST: {
            value: redisHost
          }
          CLICKHOUSE_DATABASE: {
            value: 'posthog'
          }
          CLICKHOUSE_HOST: {
            value: clickhouseHost
          }
          CLICKHOUSE_SECURE: {
            value: 'false'
          }
          CLICKHOUSE_VERIFY: {
            value: 'false'
          }
          COOKIELESS_REDIS_HOST: {
            value: redisHost
          }
          COOKIELESS_REDIS_PORT: {
            value: '6379'
          }
          ENCRYPTION_SALT_KEYS: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'ENCRYPTION_SALT_KEYS'
              }
            }
          }
          KAFKA_HOSTS: {
            value: kafkaHosts
          }
          PERSONHOG_ADDR: {
            value: '${personhogRouterContainer.properties.hosts.personhogRouter}:50052'
          }
          PERSONHOG_ENABLED: {
            value: 'true'
          }
          PLUGIN_SERVER_MODE: {
            value: 'ingestion-v2-combined'
          }
          POSTHOG_DB_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: postgresSecret.name
                key: 'password'
              }
            }
          }
          REDIS_URL: {
            value: redisUrl
          }
        }
      }
      kafkaInit: {
        image: 'docker.io/redpandadata/redpanda:v25.1.9'
        command: [
          '/bin/sh'
          '-c'
          'until rpk topic list --brokers "$KAFKA_BROKERS"; do sleep 2; done; for topic in clickhouse_events_json clickhouse_ai_events_json clickhouse_heatmap_events clickhouse_flag_evaluations clickhouse_ingestion_warnings events_plugin_ingestion_ai events_plugin_ingestion_dlq events_plugin_ingestion_overflow events_plugin_ingestion_async ingestion-clientwarnings-main-1 heatmaps_ingestion clickhouse_groups clickhouse_person clickhouse_person_distinct_id clickhouse_app_metrics2 log_entries clickhouse_tophog; do rpk topic create "$topic" --brokers "$KAFKA_BROKERS" -p 1 -r 1 || rpk topic list --brokers "$KAFKA_BROKERS" | grep -q "$topic"; done'
        ]
        env: {
          KAFKA_BROKERS: {
            value: kafkaHosts
          }
        }
        initContainer: true
      }
    }
  }
}

resource ingestionLogsContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'ingestion-logs'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'nodejs/src/index.ts'
    containers: {
      ingestionLogs: {
        image: 'docker.io/posthog/posthog-node@sha256:863e76e040ad41aef79f605c33ec71f1529bddf94cfd88941c935da9bde97235'
        args: [
          '/bin/sh'
          '-c'
          'export DATABASE_URL="${postgresDsn}"; exec node nodejs/dist/index.js'
        ]
        env: {
          CDP_REDIS_HOST: {
            value: redisHost
          }
          ENCRYPTION_SALT_KEYS: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'ENCRYPTION_SALT_KEYS'
              }
            }
          }
          KAFKA_HOSTS: {
            value: kafkaHosts
          }
          LOGS_REDIS_HOST: {
            value: redisHost
          }
          LOGS_REDIS_TLS: {
            value: 'false'
          }
          PLUGIN_SERVER_MODE: {
            value: 'ingestion-logs'
          }
          POSTHOG_DB_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: postgresSecret.name
                key: 'password'
              }
            }
          }
          REDIS_URL: {
            value: redisUrl
          }
        }
      }
    }
  }
}

resource ingestionSessionreplayContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'ingestion-sessionreplay'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'nodejs/src/index.ts'
    containers: {
      ingestionSessionreplay: {
        image: 'docker.io/posthog/posthog-node@sha256:863e76e040ad41aef79f605c33ec71f1529bddf94cfd88941c935da9bde97235'
        args: [
          '/bin/sh'
          '-c'
          'export DATABASE_URL="${postgresDsn}"; exec node nodejs/dist/index.js'
        ]
        env: {
          ENCRYPTION_SALT_KEYS: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'ENCRYPTION_SALT_KEYS'
              }
            }
          }
          KAFKA_HOSTS: {
            value: kafkaHosts
          }
          PLUGIN_SERVER_MODE: {
            value: 'recordings-blob-ingestion-v2'
          }
          POSTHOG_DB_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: postgresSecret.name
                key: 'password'
              }
            }
          }
          REDIS_URL: {
            value: redisUrl
          }
          SESSION_RECORDING_V2_S3_ACCESS_KEY_ID: {
            value: 'any'
          }
          SESSION_RECORDING_V2_S3_ENDPOINT: {
            value: seaweedfsEndpoint
          }
          SESSION_RECORDING_V2_S3_SECRET_ACCESS_KEY: {
            value: 'any'
          }
          SESSION_RECORDING_V2_S3_TIMEOUT_MS: {
            value: '120000'
          }
        }
      }
    }
  }
}

resource ingestionTracesContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'ingestion-traces'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'nodejs/src/index.ts'
    containers: {
      ingestionTraces: {
        image: 'docker.io/posthog/posthog-node@sha256:863e76e040ad41aef79f605c33ec71f1529bddf94cfd88941c935da9bde97235'
        args: [
          '/bin/sh'
          '-c'
          'export DATABASE_URL="${postgresDsn}"; exec node nodejs/dist/index.js'
        ]
        env: {
          KAFKA_HOSTS: {
            value: kafkaHosts
          }
          PLUGIN_SERVER_MODE: {
            value: 'ingestion-traces'
          }
          POSTHOG_DB_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: postgresSecret.name
                key: 'password'
              }
            }
          }
          REDIS_URL: {
            value: redisUrl
          }
          TRACES_REDIS_HOST: {
            value: redisHost
          }
          TRACES_REDIS_TLS: {
            value: 'false'
          }
        }
      }
    }
  }
}

resource kafkaContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'kafka'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'posthog/kafka_client/client.py#L203'
    containers: {
      kafka: {
        image: 'docker.io/redpandadata/redpanda:v25.1.9'
        args: [
          'redpanda'
          'start'
          '--kafka-addr internal://0.0.0.0:9092'
          '--advertise-kafka-addr internal://kafka-kafka:9092'
          '--rpc-addr kafka-kafka:33145'
          '--advertise-rpc-addr kafka-kafka:33145'
          '--mode dev-container'
          '--smp 2'
          '--memory 3G'
          '--reserve-memory 500M'
          '--overprovisioned'
          '--set redpanda.empty_seed_starts_cluster=false'
          '--seeds kafka-kafka:33145'
          '--set redpanda.auto_create_topics_enabled=true'
        ]
        env: {
          ALLOW_PLAINTEXT_LISTENER: {
            value: 'true'
          }
        }
        ports: {
          kafka: {
            containerPort: 9092
          }
        }
        volumeMounts: [
          {
            volumeName: 'data'
            mountPath: '/var/lib/redpanda/data'
          }
        ]
      }
    }
    volumes: {
      data: {
        emptyDir: {
          medium: 'disk'
        }
      }
    }
  }
}

resource livestreamContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'livestream'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'livestream/main.go#L27'
    containers: {
      livestream: {
        image: 'ghcr.io/posthog/posthog/livestream@sha256:6926f340b72d609e43cee5aa8b75a85cfdc77d182e610dafafdd81d3b2ab53f5'
        env: {
          LIVESTREAM_JWT_SECRET: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'SECRET_KEY'
              }
            }
          }
        }
        ports: {
          web: {
            containerPort: 8080
          }
        }
        volumeMounts: [
          {
            volumeName: 'config'
            mountPath: '/configs'
          }
        ]
      }
    }
    volumes: {
      config: {
        secretName: livestreamConfig.name
      }
    }
  }
}

resource objectstorageContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'objectstorage'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'posthog/storage/object_storage.py#L466'
    containers: {
      objectstorage: {
        image: 'chrislusf/seaweedfs:4.29'
        command: [
          '/bin/sh'
          '-c'
          '( until echo "s3.bucket.list" | /usr/bin/weed shell -master=localhost:19001 >/dev/null 2>&1; do sleep 2; done; echo "s3.configure -access_key=object_storage_root_user -secret_key=$OBJECT_STORAGE_SECRET_ACCESS_KEY -user=posthog -actions=Admin -apply" | /usr/bin/weed shell -master=localhost:19001 || true; echo "s3.configure -user=anonymous -actions=Admin -apply" | /usr/bin/weed shell -master=localhost:19001 || true; for b in posthog ducklake-dev ai-blobs; do echo "s3.bucket.create -name $b" | /usr/bin/weed shell -master=localhost:19001 || true; done ) & exec /usr/bin/weed server -master.port=19001 -s3 -s3.port=19000 -dir=/data -volume.max=1000 -master.volumePreallocate=false'
        ]
        env: {
          OBJECT_STORAGE_SECRET_ACCESS_KEY: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'OBJECT_STORAGE_SECRET_ACCESS_KEY'
              }
            }
          }
        }
        ports: {
          s3: {
            containerPort: 19000
          }
        }
        volumeMounts: [
          {
            volumeName: 'data'
            mountPath: '/data'
          }
        ]
      }
    }
    volumes: {
      data: {
        persistentVolume: {
          accessMode: 'ReadWriteOnce'
          resourceId: objectstorageDataVolume.id
        }
      }
    }
  }
}

resource personhogReplicaContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'personhog-replica'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'rust/personhog-replica/src/main.rs'
    containers: {
      personhogReplica: {
        image: 'ghcr.io/posthog/posthog/personhog-replica@sha256:6f910c7bd09df3cee3a8007d2497e3483b1e43fc36ccc198ae23dc131f6b04bb'
        command: [
          '/bin/sh'
          '-c'
          'export PRIMARY_DATABASE_URL="${postgresDsn}"; exec /usr/local/bin/personhog-replica'
        ]
        env: {
          GRPC_ADDRESS: {
            value: '0.0.0.0:50051'
          }
          METRICS_PORT: {
            value: '9100'
          }
          POSTHOG_DB_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: postgresSecret.name
                key: 'password'
              }
            }
          }
          RUST_LOG: {
            value: 'info'
          }
        }
        ports: {
          grpc: {
            containerPort: 50051
          }
        }
      }
    }
  }
}

resource personhogRouterContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'personhog-router'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'rust/personhog-router/src/main.rs'
    containers: {
      personhogRouter: {
        image: 'ghcr.io/posthog/posthog/personhog-router@sha256:7e7a50cc2ec2aa73b95271a6d955a68f5ba7e7a92b313b3498fb470204540357'
        env: {
          BACKEND_TIMEOUT_MS: {
            value: '5000'
          }
          GRPC_ADDRESS: {
            value: '0.0.0.0:50052'
          }
          METRICS_PORT: {
            value: '9101'
          }
          REPLICA_URL: {
            value: 'http://${personhogReplicaContainer.properties.hosts.personhogReplica}:50051'
          }
          RUST_LOG: {
            value: 'info'
          }
        }
        ports: {
          grpc: {
            containerPort: 50052
          }
        }
      }
    }
  }
}

resource pluginsContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'plugins'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'nodejs/src/index.ts'
    containers: {
      plugins: {
        image: 'docker.io/posthog/posthog-node@sha256:863e76e040ad41aef79f605c33ec71f1529bddf94cfd88941c935da9bde97235'
        args: [
          '/bin/sh'
          '-c'
          'export DATABASE_URL="${postgresDsn}"; export PERSONS_DATABASE_URL="$DATABASE_URL"; export BEHAVIORAL_COHORTS_DATABASE_URL="$DATABASE_URL"; exec node nodejs/dist/index.js'
        ]
        env: {
          CDP_REDIS_HOST: {
            value: redisHost
          }
          CDP_REDIS_PORT: {
            value: '6379'
          }
          CDP_VALKEY_HOST: {
            value: valkeyHost
          }
          CDP_VALKEY_PORT: {
            value: '6379'
          }
          CLICKHOUSE_DATABASE: {
            value: 'posthog'
          }
          CLICKHOUSE_HOST: {
            value: clickhouseHost
          }
          CLICKHOUSE_SECURE: {
            value: 'false'
          }
          CLICKHOUSE_VERIFY: {
            value: 'false'
          }
          ENCRYPTION_SALT_KEYS: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'ENCRYPTION_SALT_KEYS'
              }
            }
          }
          KAFKA_HOSTS: {
            value: kafkaHosts
          }
          LOGS_REDIS_HOST: {
            value: redisHost
          }
          LOGS_REDIS_PORT: {
            value: '6379'
          }
          LOGS_REDIS_TLS: {
            value: 'false'
          }
          OBJECT_STORAGE_ACCESS_KEY_ID: {
            value: 'object_storage_root_user'
          }
          OBJECT_STORAGE_ENABLED: {
            value: 'true'
          }
          OBJECT_STORAGE_ENDPOINT: {
            value: objectStorageEndpoint
          }
          OBJECT_STORAGE_PUBLIC_ENDPOINT: {
            value: siteUrl
          }
          OBJECT_STORAGE_SECRET_ACCESS_KEY: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'OBJECT_STORAGE_SECRET_ACCESS_KEY'
              }
            }
          }
          POSTHOG_DB_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: postgresSecret.name
                key: 'password'
              }
            }
          }
          REDIS_URL: {
            value: redisUrl
          }
          SITE_URL: {
            value: siteUrl
          }
          TRACES_REDIS_HOST: {
            value: redisHost
          }
          TRACES_REDIS_PORT: {
            value: '6379'
          }
          TRACES_REDIS_TLS: {
            value: 'false'
          }
        }
        ports: {
          web: {
            containerPort: 6738
          }
        }
      }
    }
  }
}

resource propertyDefsRsContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'property-defs-rs'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'rust/property-defs-rs/src/main.rs'
    containers: {
      propertyDefsRs: {
        image: 'ghcr.io/posthog/posthog/property-defs-rs@sha256:c385998bf5ec7072825ebef2e080db36887924103013ba84eb29db7a9eb1deab'
        command: [
          '/bin/sh'
          '-c'
          'export DATABASE_URL="${postgresDsn}"; exec /usr/local/bin/property-defs-rs'
        ]
        env: {
          FILTER_MODE: {
            value: 'opt-out'
          }
          KAFKA_HOSTS: {
            value: kafkaHosts
          }
          POSTHOG_DB_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: postgresSecret.name
                key: 'password'
              }
            }
          }
          SKIP_READS: {
            value: 'false'
          }
          SKIP_WRITES: {
            value: 'false'
          }
        }
      }
    }
  }
}

resource recordingApiContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'recording-api'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'nodejs/src/index.ts'
    containers: {
      recordingApi: {
        image: 'docker.io/posthog/posthog-node@sha256:863e76e040ad41aef79f605c33ec71f1529bddf94cfd88941c935da9bde97235'
        args: [
          '/bin/sh'
          '-c'
          'export DATABASE_URL="${postgresDsn}"; exec node nodejs/dist/index.js'
        ]
        env: {
          CLICKHOUSE_DATABASE: {
            value: 'posthog'
          }
          CLICKHOUSE_HOST: {
            value: clickhouseHost
          }
          CLICKHOUSE_SECURE: {
            value: 'false'
          }
          CLICKHOUSE_VERIFY: {
            value: 'false'
          }
          ENCRYPTION_SALT_KEYS: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'ENCRYPTION_SALT_KEYS'
              }
            }
          }
          INTERNAL_API_SECRET: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'INTERNAL_API_SECRET'
              }
            }
          }
          PLUGIN_SERVER_MODE: {
            value: 'recording-api'
          }
          POSTHOG_DB_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: postgresSecret.name
                key: 'password'
              }
            }
          }
          REDIS_URL: {
            value: redisUrl
          }
          SESSION_RECORDING_API_REDIS_HOST: {
            value: redisHost
          }
          SESSION_RECORDING_API_REDIS_PORT: {
            value: '6379'
          }
          SESSION_RECORDING_V2_S3_ACCESS_KEY_ID: {
            value: 'any'
          }
          SESSION_RECORDING_V2_S3_ENDPOINT: {
            value: seaweedfsEndpoint
          }
          SESSION_RECORDING_V2_S3_SECRET_ACCESS_KEY: {
            value: 'any'
          }
        }
        ports: {
          web: {
            containerPort: 6738
          }
        }
      }
    }
  }
}

resource redisContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'redis'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'posthog/redis.py#L29'
    containers: {
      redis: {
        image: 'redis:7.2-alpine'
        args: [
          'redis-server'
          '--maxmemory-policy'
          'allkeys-lru'
          '--maxmemory'
          '200mb'
        ]
        ports: {
          redis: {
            containerPort: 6379
          }
        }
        volumeMounts: [
          {
            volumeName: 'data'
            mountPath: '/data'
          }
        ]
      }
    }
    volumes: {
      data: {
        persistentVolume: {
          accessMode: 'ReadWriteOnce'
          resourceId: redisDataVolume.id
        }
      }
    }
  }
}

resource replayCaptureContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'replay-capture'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'rust/capture/src/main.rs'
    containers: {
      replayCapture: {
        image: 'ghcr.io/posthog/posthog/capture@sha256:89d816e0125632911001189fe3151cbee07a60f7b47997dc208f34978f03a476'
        env: {
          ADDRESS: {
            value: '0.0.0.0:3000'
          }
          CAPTURE_MODE: {
            value: 'recordings'
          }
          KAFKA_HOSTS: {
            value: kafkaHosts
          }
          KAFKA_TOPIC: {
            value: 'session_recording_snapshot_item_events'
          }
          REDIS_URL: {
            value: redisUrl
          }
        }
        ports: {
          web: {
            containerPort: 3000
          }
        }
      }
    }
  }
}

resource seaweedfsContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'seaweedfs'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'posthog/settings/session_replay_v2.py#L9'
    containers: {
      seaweedfs: {
        image: 'chrislusf/seaweedfs:4.29'
        command: [
          '/bin/sh'
          '-c'
          '( until echo "s3.bucket.list" | /usr/bin/weed shell -master=localhost:9333 >/dev/null 2>&1; do sleep 5; done; echo "s3.bucket.create -name posthog" | /usr/bin/weed shell -master=localhost:9333 || true ) & exec /usr/bin/weed server -s3 -s3.port=8333 -dir=/data -volume.max=1000'
        ]
        ports: {
          s3: {
            containerPort: 8333
          }
        }
        volumeMounts: [
          {
            volumeName: 'data'
            mountPath: '/data'
          }
        ]
      }
    }
    volumes: {
      data: {
        persistentVolume: {
          accessMode: 'ReadWriteOnce'
          resourceId: seaweedfsDataVolume.id
        }
      }
    }
  }
}

resource temporalContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'temporal'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'posthog/temporal/common/client.py#L59'
    containers: {
      temporal: {
        image: 'temporalio/auto-setup:1.26.2'
        env: {
          DB: {
            value: 'postgres12'
          }
          DB_PORT: {
            value: '5432'
          }
          DYNAMIC_CONFIG_FILE_PATH: {
            value: 'config/dynamicconfig/development-sql.yaml'
          }
          ENABLE_ES: {
            value: 'false'
          }
          POSTGRES_PWD: {
            valueFrom: {
              secretKeyRef: {
                secretName: postgresSecret.name
                key: 'password'
              }
            }
          }
          POSTGRES_SEEDS: {
            value: postgresDb.properties.host
          }
          POSTGRES_USER: {
            value: 'myadmin'
          }
        }
        ports: {
          grpc: {
            containerPort: 7233
          }
        }
      }
    }
  }
}

resource temporalDjangoWorkerContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'temporal-django-worker'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'bin/temporal-django-worker'
    containers: {
      temporalDjangoWorker: {
        image: 'docker.io/posthog/posthog@sha256:c84cde1bd3fcf31e09b8b23ea629dab55cf1f675709e83d6110618b994658b11'
        args: [
          '/bin/sh'
          '-c'
          'export DATABASE_URL="${postgresDsn}"; export PERSONS_DB_WRITER_URL="$DATABASE_URL"; export PERSONS_DB_READER_URL="$DATABASE_URL"; exec ./bin/temporal-django-worker'
        ]
        env: {
          API_QUERIES_PER_TEAM: {
            value: '{"1": 100}'
          }
          BROWSERLESS_CDP_URL: {
            value: 'ws://${browserlessContainer.properties.hosts.browserless}:3000'
          }
          BROWSERLESS_TOKEN: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'BROWSERLESS_TOKEN'
              }
            }
          }
          CDP_API_URL: {
            value: 'http://${pluginsContainer.properties.hosts.plugins}:6738'
          }
          CLICKHOUSE_DATABASE: {
            value: 'posthog'
          }
          CLICKHOUSE_HOST: {
            value: clickhouseHost
          }
          CLICKHOUSE_LOGS_CLUSTER_HOST: {
            value: clickhouseHost
          }
          CLICKHOUSE_LOGS_CLUSTER_SECURE: {
            value: 'false'
          }
          CLICKHOUSE_SECURE: {
            value: 'false'
          }
          CLICKHOUSE_VERIFY: {
            value: 'false'
          }
          DEPLOYMENT: {
            value: 'hobby'
          }
          ENCRYPTION_SALT_KEYS: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'ENCRYPTION_SALT_KEYS'
              }
            }
          }
          FEATURE_FLAGS_SERVICE_URL: {
            value: 'http://${featureFlagsContainer.properties.hosts.featureFlags}:3001'
          }
          FLAGS_REDIS_ENABLED: {
            value: 'false'
          }
          HEATMAP_BROWSERLESS_TOKEN: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'BROWSERLESS_TOKEN'
              }
            }
          }
          HEATMAP_BROWSERLESS_URL: {
            value: 'http://${browserlessContainer.properties.hosts.browserless}:3000'
          }
          KAFKA_HOSTS: {
            value: kafkaHosts
          }
          OBJECT_STORAGE_ACCESS_KEY_ID: {
            value: 'object_storage_root_user'
          }
          OBJECT_STORAGE_ENABLED: {
            value: 'true'
          }
          OBJECT_STORAGE_ENDPOINT: {
            value: objectStorageEndpoint
          }
          OBJECT_STORAGE_PUBLIC_ENDPOINT: {
            value: siteUrl
          }
          OBJECT_STORAGE_SECRET_ACCESS_KEY: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'OBJECT_STORAGE_SECRET_ACCESS_KEY'
              }
            }
          }
          OTEL_SDK_DISABLED: {
            value: 'true'
          }
          POSTHOG_DB_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: postgresSecret.name
                key: 'password'
              }
            }
          }
          REDIS_URL: {
            value: redisUrl
          }
          SECRET_KEY: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'SECRET_KEY'
              }
            }
          }
          SESSION_RECORDING_V2_S3_ACCESS_KEY_ID: {
            value: 'any'
          }
          SESSION_RECORDING_V2_S3_ENDPOINT: {
            value: seaweedfsEndpoint
          }
          SESSION_RECORDING_V2_S3_SECRET_ACCESS_KEY: {
            value: 'any'
          }
          SITE_URL: {
            value: siteUrl
          }
          TEMPORAL_HOST: {
            value: temporalContainer.properties.hosts.temporal
          }
        }
      }
    }
  }
}

resource valkeyContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'valkey'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'nodejs/src/cdp/cdp-services.ts#L264'
    containers: {
      valkey: {
        image: 'valkey/valkey:8.1-alpine'
        args: [
          'valkey-server'
          '--maxmemory-policy'
          'allkeys-lru'
          '--maxmemory'
          '200mb'
        ]
        ports: {
          redis: {
            containerPort: 6379
          }
        }
      }
    }
  }
}

resource webContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'web'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'bin/docker'
    containers: {
      migrate: {
        image: 'docker.io/posthog/posthog@sha256:c84cde1bd3fcf31e09b8b23ea629dab55cf1f675709e83d6110618b994658b11'
        args: [
          '/bin/sh'
          '-c'
          'export DATABASE_URL="${postgresDsn}"; python manage.py migrate && python manage.py migrate_clickhouse'
        ]
        env: {
          CLICKHOUSE_DATABASE: {
            value: 'posthog'
          }
          CLICKHOUSE_HOST: {
            value: clickhouseHost
          }
          CLICKHOUSE_SECURE: {
            value: 'false'
          }
          CLICKHOUSE_VERIFY: {
            value: 'false'
          }
          KAFKA_HOSTS: {
            value: kafkaHosts
          }
          POSTHOG_DB_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: postgresSecret.name
                key: 'password'
              }
            }
          }
          REDIS_URL: {
            value: redisUrl
          }
          SECRET_KEY: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'SECRET_KEY'
              }
            }
          }
          SKIP_ASYNC_MIGRATIONS_SETUP: {
            value: '0'
          }
        }
        initContainer: true
      }
      web: {
        image: 'docker.io/posthog/posthog@sha256:c84cde1bd3fcf31e09b8b23ea629dab55cf1f675709e83d6110618b994658b11'
        args: [
          '/bin/sh'
          '-c'
          'export DATABASE_URL="${postgresDsn}"; export PERSONS_DB_WRITER_URL="$DATABASE_URL"; export PERSONS_DB_READER_URL="$DATABASE_URL"; exec ./bin/docker'
        ]
        env: {
          API_QUERIES_PER_TEAM: {
            value: '{"1": 100}'
          }
          CDP_API_URL: {
            value: 'http://${pluginsContainer.properties.hosts.plugins}:6738'
          }
          CLICKHOUSE_DATABASE: {
            value: 'posthog'
          }
          CLICKHOUSE_HOST: {
            value: clickhouseHost
          }
          CLICKHOUSE_LOGS_CLUSTER_HOST: {
            value: clickhouseHost
          }
          CLICKHOUSE_LOGS_CLUSTER_SECURE: {
            value: 'false'
          }
          CLICKHOUSE_SECURE: {
            value: 'false'
          }
          CLICKHOUSE_VERIFY: {
            value: 'false'
          }
          DEPLOYMENT: {
            value: 'hobby'
          }
          DISABLE_SECURE_SSL_REDIRECT: {
            value: 'true'
          }
          ENCRYPTION_SALT_KEYS: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'ENCRYPTION_SALT_KEYS'
              }
            }
          }
          FEATURE_FLAGS_SERVICE_URL: {
            value: 'http://${featureFlagsContainer.properties.hosts.featureFlags}:3001'
          }
          FLAGS_REDIS_ENABLED: {
            value: 'false'
          }
          INTERNAL_API_SECRET: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'INTERNAL_API_SECRET'
              }
            }
          }
          IS_BEHIND_PROXY: {
            value: 'true'
          }
          KAFKA_HOSTS: {
            value: kafkaHosts
          }
          LIVESTREAM_HOST: {
            value: '${siteUrl}/livestream'
          }
          OBJECT_STORAGE_ACCESS_KEY_ID: {
            value: 'object_storage_root_user'
          }
          OBJECT_STORAGE_ENABLED: {
            value: 'true'
          }
          OBJECT_STORAGE_ENDPOINT: {
            value: objectStorageEndpoint
          }
          OBJECT_STORAGE_PUBLIC_ENDPOINT: {
            value: siteUrl
          }
          OBJECT_STORAGE_SECRET_ACCESS_KEY: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'OBJECT_STORAGE_SECRET_ACCESS_KEY'
              }
            }
          }
          OTEL_SDK_DISABLED: {
            value: 'true'
          }
          PERSONHOG_ADDR: {
            value: '${personhogRouterContainer.properties.hosts.personhogRouter}:50052'
          }
          PERSONHOG_ENABLED: {
            value: 'true'
          }
          POSTHOG_DB_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: postgresSecret.name
                key: 'password'
              }
            }
          }
          RECORDING_API_URL: {
            value: 'http://${recordingApiContainer.properties.hosts.recordingApi}:6738'
          }
          REDIS_URL: {
            value: redisUrl
          }
          SECRET_KEY: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'SECRET_KEY'
              }
            }
          }
          SESSION_RECORDING_V2_S3_ACCESS_KEY_ID: {
            value: 'any'
          }
          SESSION_RECORDING_V2_S3_ENDPOINT: {
            value: seaweedfsEndpoint
          }
          SESSION_RECORDING_V2_S3_SECRET_ACCESS_KEY: {
            value: 'any'
          }
          SITE_URL: {
            value: siteUrl
          }
        }
        ports: {
          web: {
            containerPort: 8000
          }
        }
      }
    }
  }
}

resource workerContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'worker'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'bin/docker-worker-celery'
    containers: {
      worker: {
        image: 'docker.io/posthog/posthog@sha256:c84cde1bd3fcf31e09b8b23ea629dab55cf1f675709e83d6110618b994658b11'
        args: [
          '/bin/sh'
          '-c'
          'export DATABASE_URL="${postgresDsn}"; export PERSONS_DB_WRITER_URL="$DATABASE_URL"; export PERSONS_DB_READER_URL="$DATABASE_URL"; exec ./bin/docker-worker-celery --with-scheduler'
        ]
        env: {
          API_QUERIES_PER_TEAM: {
            value: '{"1": 100}'
          }
          BROWSERLESS_CDP_URL: {
            value: 'ws://${browserlessContainer.properties.hosts.browserless}:3000'
          }
          BROWSERLESS_TOKEN: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'BROWSERLESS_TOKEN'
              }
            }
          }
          CDP_API_URL: {
            value: 'http://${pluginsContainer.properties.hosts.plugins}:6738'
          }
          CLICKHOUSE_DATABASE: {
            value: 'posthog'
          }
          CLICKHOUSE_HOST: {
            value: clickhouseHost
          }
          CLICKHOUSE_LOGS_CLUSTER_HOST: {
            value: clickhouseHost
          }
          CLICKHOUSE_LOGS_CLUSTER_SECURE: {
            value: 'false'
          }
          CLICKHOUSE_SECURE: {
            value: 'false'
          }
          CLICKHOUSE_VERIFY: {
            value: 'false'
          }
          DEPLOYMENT: {
            value: 'hobby'
          }
          ENCRYPTION_SALT_KEYS: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'ENCRYPTION_SALT_KEYS'
              }
            }
          }
          FEATURE_FLAGS_SERVICE_URL: {
            value: 'http://${featureFlagsContainer.properties.hosts.featureFlags}:3001'
          }
          FLAGS_REDIS_ENABLED: {
            value: 'false'
          }
          HEATMAP_BROWSERLESS_TOKEN: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'BROWSERLESS_TOKEN'
              }
            }
          }
          HEATMAP_BROWSERLESS_URL: {
            value: 'http://${browserlessContainer.properties.hosts.browserless}:3000'
          }
          INTERNAL_API_SECRET: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'INTERNAL_API_SECRET'
              }
            }
          }
          KAFKA_HOSTS: {
            value: kafkaHosts
          }
          OBJECT_STORAGE_ACCESS_KEY_ID: {
            value: 'object_storage_root_user'
          }
          OBJECT_STORAGE_ENABLED: {
            value: 'true'
          }
          OBJECT_STORAGE_ENDPOINT: {
            value: objectStorageEndpoint
          }
          OBJECT_STORAGE_PUBLIC_ENDPOINT: {
            value: siteUrl
          }
          OBJECT_STORAGE_SECRET_ACCESS_KEY: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'OBJECT_STORAGE_SECRET_ACCESS_KEY'
              }
            }
          }
          OTEL_SDK_DISABLED: {
            value: 'true'
          }
          PERSONHOG_ADDR: {
            value: '${personhogRouterContainer.properties.hosts.personhogRouter}:50052'
          }
          PERSONHOG_ENABLED: {
            value: 'true'
          }
          POSTHOG_DB_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: postgresSecret.name
                key: 'password'
              }
            }
          }
          POSTHOG_SKIP_MIGRATION_CHECKS: {
            value: '1'
          }
          RECORDING_API_URL: {
            value: 'http://${recordingApiContainer.properties.hosts.recordingApi}:6738'
          }
          REDIS_URL: {
            value: redisUrl
          }
          SECRET_KEY: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'SECRET_KEY'
              }
            }
          }
          SESSION_RECORDING_V2_S3_ACCESS_KEY_ID: {
            value: 'any'
          }
          SESSION_RECORDING_V2_S3_ENDPOINT: {
            value: seaweedfsEndpoint
          }
          SESSION_RECORDING_V2_S3_SECRET_ACCESS_KEY: {
            value: 'any'
          }
          SITE_URL: {
            value: siteUrl
          }
        }
      }
    }
  }
}

resource zookeeperContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'zookeeper'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'docker/clickhouse/config.xml#L181'
    containers: {
      zookeeper: {
        image: 'zookeeper:3.7.0'
        env: {
          ZOO_AUTOPURGE_PURGEINTERVAL: {
            value: '1'
          }
          ZOO_AUTOPURGE_SNAPRETAINCOUNT: {
            value: '3'
          }
        }
        ports: {
          client: {
            containerPort: 2181
          }
        }
        volumeMounts: [
          {
            volumeName: 'data'
            mountPath: '/data'
          }
        ]
      }
    }
    volumes: {
      data: {
        persistentVolume: {
          accessMode: 'ReadWriteOnce'
          resourceId: zookeeperDataVolume.id
        }
      }
    }
  }
}

resource posthogRoute 'Radius.Compute/routes@2025-08-01-preview' = {
  name: 'posthog-route'
  properties: {
    environment: environment
    application: posthogApp.id
    codeReference: 'docker-compose.base.yml#L6'
    kind: 'HTTP'
    rules: [
      {
        matches: [
          {
            httpPath: '/s'
          }
        ]
        destinationContainer: {
          resourceId: replayCaptureContainer.id
          containerName: 'replayCapture'
          containerPort: 3000
        }
      }
      {
        matches: [
          {
            httpPath: '/e'
          }
          {
            httpPath: '/i/v0'
          }
          {
            httpPath: '/i/v1/analytics/events'
          }
          {
            httpPath: '/batch'
          }
          {
            httpPath: '/capture'
          }
        ]
        destinationContainer: {
          resourceId: captureContainer.id
          containerName: 'capture'
          containerPort: 3000
        }
      }
      {
        matches: [
          {
            httpPath: '/i/v1/logs'
          }
          {
            httpPath: '/i/v1/traces'
          }
          {
            httpPath: '/i/v1/metrics'
          }
        ]
        destinationContainer: {
          resourceId: captureLogsContainer.id
          containerName: 'captureLogs'
          containerPort: 4318
        }
      }
      {
        matches: [
          {
            httpPath: '/flags'
          }
          {
            httpPath: '/api/feature_flag/local_evaluation'
          }
        ]
        destinationContainer: {
          resourceId: featureFlagsContainer.id
          containerName: 'featureFlags'
          containerPort: 3001
        }
      }
      {
        matches: [
          {
            httpPath: '/surveys'
          }
          {
            httpPath: '/api/surveys'
          }
          {
            httpPath: '/array'
          }
        ]
        destinationContainer: {
          resourceId: hypercacheServerContainer.id
          containerName: 'hypercacheServer'
          containerPort: 3002
        }
      }
      {
        matches: [
          {
            httpPath: '/public/webhooks'
          }
          {
            httpPath: '/public/m'
          }
        ]
        destinationContainer: {
          resourceId: pluginsContainer.id
          containerName: 'plugins'
          containerPort: 6738
        }
      }
      {
        matches: [
          {
            httpPath: '/livestream'
          }
        ]
        destinationContainer: {
          resourceId: livestreamContainer.id
          containerName: 'livestream'
          containerPort: 8080
        }
      }
      {
        matches: [
          {
            httpPath: '/'
          }
        ]
        destinationContainer: {
          resourceId: webContainer.id
          containerName: 'web'
          containerPort: 8000
        }
      }
    ]
  }
}
