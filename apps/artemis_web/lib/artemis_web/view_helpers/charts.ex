defmodule ArtemisWeb.ViewHelper.Charts do
  use Phoenix.HTML

  @doc """
  Render javascript chart
  """
  def render_chart(chart_options \\ %{}) do
    assigns = [
      chart_id: Artemis.Helpers.UUID.call(),
      chart_options: get_encoded_chart_options(chart_options)
    ]

    Phoenix.View.render(ArtemisWeb.LayoutView, "chart.html", assigns)
  end

  defp get_encoded_chart_options(passed_options) do
    get_default_chart_options()
    |> Artemis.Helpers.deep_merge(passed_options)
    |> Jason.encode!()
    |> raw()
  end

  defp get_default_chart_options() do
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
          show: true,
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
        fontSize: "14px"
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
end
