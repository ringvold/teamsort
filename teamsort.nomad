job "teamsort" {

  # Spread the tasks in this job between us-west-1 and us-east-1.
  datacenters = ["dc1"]

  spread {
    attribute = "${node.unique.name}"
    weight    = 100
  }

  # Run this job as a "service" type. Each job type has different
  # properties. See the documentation below for more examples.
  type = "service"

  # Specify this job to have rolling updates, two-at-a-time, with
  # 30 second intervals.
  update {
    stagger      = "30s"
    max_parallel = 2
  }


  # A group defines a series of tasks that should be co-located
  # on the same client (host). All tasks within a group will be
  # placed on the same host.
  group "teamsort" {
    # Specify the number of these tasks we want.
    count = 2

    network {
      # This requests a dynamic port named "http". This will
      # be something like "46283", but we refer to it via the
      # label "http".
      port "http" {
          to = -1
      }
    }

    # The service block tells Nomad how to register this service
    # with Consul for service discovery and monitoring.
    service {
      # This tells Consul to monitor the service on the port
      # labelled "http". Since Nomad allocates high dynamic port
      # numbers, we use labels to refer to them.
      port = "http"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.teamsort_http.rule=Host(`teamsort.harald.io`)",
        "traefik.http.routers.teamsort_https.rule=Host(`teamsort.harald.io`)",

      ]
      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    # Create an individual task (unit of work). This particular
    # task utilizes a Docker container to front a web application.
    task "teamsort" {
      env {
        PORT    = "${NOMAD_PORT_http}"
      }

      # Specify the driver to be "docker". Nomad supports
      # multiple drivers.
      driver = "docker"

      # Configuration is specific to each driver.
      config {
        image = "ghcr.io/ringvold/teamsort:latest"
        ports = ["http"]
      }


      # Specify the maximum resources required to run the task,
      # include CPU and memory.
      resources {
        cpu    = 1000 # MHz
        memory = 500 # MB
      }
    }
  }
}
