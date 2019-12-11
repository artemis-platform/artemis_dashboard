defmodule ArtemisWeb.ViewHelper.Charts do
  use Phoenix.HTML

  @doc """
  Include raw javascript function in javascript chart options:

      %{
        formatter: raw_javascript_function(""
          function (value) {
            console.log(value);

            return value + "%";
          }
        "")
      }

  """
  def raw_javascript_function(text) do
    "raw_javascript_function(#{text})"
  end

  @doc """
  Return a JavaScript compatible data type
  """
  def get_encoded_chart_options(passed_options) do
    get_global_chart_options()
    |> Artemis.Helpers.deep_merge(passed_options)
    |> Jason.encode!()
    |> decode_raw_javascript_functions()
    |> raw()
  end

  defp decode_raw_javascript_functions(input) do
    regex = ~r/:\"raw_javascript_function\((.*?)\)\"/

    Regex.replace(regex, input, fn _, capture ->
      ": " <> Macro.unescape_string(capture)
    end)
  end

  defp get_global_chart_options() do
    %{
      chart: %{
        animations: %{
          enabled: true,
          easing: "easeinout",
          speed: 800,
          animateGradually: %{
            enabled: true,
            delay: 150
          },
          dynamicAnimation: %{
            enabled: true,
            speed: 350
          }
        },
        defaultLocale: "en",
        fontFamily: "Muli, Lato, Helvetica Neue, Arial, Helvetica, sans-serif",
        height: "100%",
        locales: [
          %{
            name: "en",
            options: %{
              months: [
                "January",
                "February",
                "March",
                "April",
                "May",
                "June",
                "July",
                "August",
                "September",
                "October",
                "November",
                "December"
              ],
              shortMonths: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
              days: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
              shortDays: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
              toolbar: %{
                download: "Download SVG",
                selection: "Selection",
                selectionZoom: "Selection Zoom",
                zoomIn: "Zoom In",
                zoomOut: "Zoom Out",
                pan: "Panning",
                reset: "Reset Zoom"
              }
            }
          }
        ],
        parentHeightOffset: 0,
        sparkline: %{
          enabled: false
        },
        toolbar: %{
          show: false,
          tools: %{
            download: true,
            selection: true,
            zoom: true,
            zoomin: true,
            zoomout: true,
            pan: true,
            reset: true,
            customIcons: []
          },
          autoSelected: "zoom"
        },
        width: "100%"
      },
      legend: %{
        show: true,
        showForSingleSeries: false,
        showForNullSeries: true,
        showForZeroSeries: true,
        position: "bottom",
        horizontalAlign: "center",
        fontFamily: "Muli, Lato, Helvetica Neue, Arial, Helvetica, sans-serif",
        fontSize: "13px"
      },
      markers: %{
        # To make visible, change to `5`
        size: 0,
        strokeColors: "#fff",
        strokeWidth: 2,
        strokeOpacity: 0.9,
        fillOpacity: 1,
        shape: "circle",
        radius: 2,
        hover: %{
          # If marker is always visible, change to `7`
          size: 0,
          sizeOffset: 3
        }
      },
      theme: %{
        mode: "light",
        palette: "palette10",
        monochrome: %{
          enabled: false,
          color: "#255aee",
          shadeTo: "light",
          shadeIntensity: 0.65
        }
      }
    }
  end

  @doc """
  Return common chart options for a specific chart types
  """
  def get_chart_type_options(:bar) do
    %{
      chart: %{
        type: "bar",
        stacked: false
      },
      legend: %{
        show: true,
        position: "bottom",
        horizontalAlign: "center",
        labels: %{
          useSeriesColors: false
        }
      },
      series: [],
      theme: %{
        mode: "light"
      },
      tooltip: %{
        enabled: true
      },
      xaxis: %{
        categories: []
      }
    }
  end

  def get_chart_type_options(:bar_horizontal) do
    %{
      chart: %{
        type: "bar",
        stacked: false
      },
      plotOptions: %{
        bar: %{
          horizontal: true
        }
      },
      legend: %{
        show: true,
        position: "bottom",
        horizontalAlign: "center",
        labels: %{
          useSeriesColors: false
        }
      },
      series: [],
      theme: %{
        mode: "light"
      },
      tooltip: %{
        enabled: true
      },
      xaxis: %{
        categories: []
      }
    }
  end

  def get_chart_type_options(:donut) do
    %{
      chart: %{
        type: "donut"
      },
      plotOptions: %{
        pie: %{
          customScale: 1,
          offsetX: 0,
          offsetY: 0,
          expandOnClick: true,
          dataLabels: %{
            show: false,
            offset: 0,
            minAngleToShowLabel: 15
          },
          donut: %{
            size: "50%",
            labels: %{
              show: true,
              name: %{
                show: true,
                fontSize: "22px",
                color: nil,
                offsetY: -6
              },
              total: %{
                show: true,
                label: "Total"
              },
              value: %{
                show: true,
                fontSize: "16px",
                color: nil,
                offsetY: 0
              }
            }
          }
        }
      },
      dataLabels: %{
        enabled: true,
        style: %{
          colors: ["rgba(255, 255, 255, 0.9)"]
        },
        formatter:
          raw_javascript_function("""
            function (percent, opts) {
              var index = opts.seriesIndex
              var name = opts.w.globals.seriesNames[index]
              var value = opts.w.globals.seriesTotals[index]

              return name
            }
          """)
      },
      legend: %{
        show: false,
        fontSize: "14px",
        textAnchor: "end",
        position: "bottom",
        horizontalAlign: "left",
        labels: %{
          useSeriesColors: true
        },
        markers: %{
          size: 0
        },
        itemMargin: %{
          horizontal: 1,
          vertical: 2
        }
      },
      labels: [],
      series: [],
      theme: %{
        mode: "light"
      },
      tooltip: %{
        enabled: false
      }
    }
  end

  def get_chart_type_options(:donut_thin) do
    %{
      chart: %{
        type: "donut"
      },
      colors: [],
      dataLabels: %{
        enabled: false
      },
      legend: %{
        show: false,
        fontSize: "14px",
        textAnchor: "end",
        position: "bottom",
        horizontalAlign: "left",
        labels: %{
          useSeriesColors: true
        },
        markers: %{
          size: 0
        },
        itemMargin: %{
          horizontal: 1,
          vertical: 2
        }
      },
      labels: [],
      plotOptions: %{
        pie: %{
          customScale: 1,
          offsetX: 0,
          offsetY: 0,
          expandOnClick: true,
          dataLabels: %{
            show: false
          },
          donut: %{
            size: "80%",
            labels: %{
              show: true,
              name: %{
                show: true,
                fontSize: "22px",
                color: nil,
                offsetY: -6
              },
              total: %{
                show: true,
                label: "Total"
              },
              value: %{
                show: true,
                fontSize: "16px",
                color: nil,
                offsetY: 0
              }
            }
          }
        }
      },
      series: [],
      stroke: %{
        show: true,
        colors: ["#fff"],
        width: 2
      },
      theme: %{
        mode: "light"
      },
      tooltip: %{
        enabled: false
      }
    }
  end

  def get_chart_type_options(:radial) do
    %{
      chart: %{
        type: "radialBar"
      },
      labels: [],
      legend: %{
        show: true,
        floating: true,
        fontSize: "14px",
        position: "left",
        offsetX: 120,
        offsetY: 136,
        textAnchor: "end",
        labels: %{
          useSeriesColors: true
        },
        markers: %{
          size: 0
        },
        itemMargin: %{
          horizontal: 0.5,
          vertical: 0
        },
        onItemClick: %{
          toggleDataSeries: false
        }
      },
      plotOptions: %{
        radialBar: %{
          inverseOrder: true,
          offsetX: 0,
          offsetY: -32,
          startAngle: -180,
          endAngle: 90,
          hollow: %{
            margin: 5,
            size: "40%",
            background: "transparent"
          },
          track: %{
            show: true,
            background: "#ddd",
            strokeWidth: "97%",
            opacity: 0.8,
            margin: 5,
            dropShadow: %{
              enabled: false,
              top: 0,
              left: 0,
              blur: 3,
              opacity: 0.5
            }
          },
          dataLabels: %{
            name: %{
              show: true,
              color: nil,
              offsetY: -6
            },
            total: %{
              show: true,
              color: nil,
              label: "Total",
              formatter:
                raw_javascript_function("""
                  function (w) {
                    var last_index = w.globals.seriesNames.length - 1
                    var name = w.globals.seriesNames[last_index]
                    var value = w.globals.seriesTotals[last_index]

                    return parseFloat(value, 10) + '%';
                  }
                """)
            },
            value: %{
              show: true,
              color: nil,
              offsetY: 0,
              formatter:
                raw_javascript_function("""
                  function (value, w) {
                    return value + '%'
                  }
                """)
            }
          }
        }
      },
      series: [],
      theme: %{
        mode: "light"
      }
    }
  end
end
