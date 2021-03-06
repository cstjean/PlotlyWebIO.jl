# ------------ #
# Web IO stuff #
# ------------ #
function setup_api_obs(p::PlotlyBase.Plot, scope::Scope)
    svg_obs = Observable(scope, "svg-string", "")
    api_obs = Dict{String,Observable}("svg" => svg_obs)
    id = string("#plot-", p.divid)

    # set up restyle
    restyle_obs = Observable(scope, "restyle_args", RestyleArgs())
    api_obs["restyle"] = restyle_obs

    onjs(restyle_obs, @js function(val)
        @var gd = this.dom.querySelector($id);
        Plotly.restyle(gd, val.data, val.traces).then(function(gd)
            Plotly.toImage(gd, $(Dict("format" => "svg")))
        end
        ).then(function(data)
            @var svg_data = data.replace("data:image/svg+xml,", "")
            $svg_obs[] = decodeURIComponent(svg_data)
        end
        );
    end)

    # set up relayout
    relayout_obs = Observable(scope, "relayout_args", RelayoutArgs())
    api_obs["relayout"] = relayout_obs

    onjs(relayout_obs, @js function(val)
        Plotly.relayout(gd, val.data).then(function(gd)
            Plotly.toImage(gd, $(Dict("format" => "svg")))
        end
        ).then(function(data)
            @var svg_data = data.replace("data:image/svg+xml,", "")
            $svg_obs[] = decodeURIComponent(svg_data)
        end
        );
    end)

    # set up update
    update_obs = Observable(scope, "update_args", UpdateArgs())
    api_obs["update"] = update_obs

    onjs(update_obs, @js function(val)
        @var gd = this.dom.querySelector($id);
        Plotly.update(gd, val.data, val.layout, val.traces).then(function(gd)
            Plotly.toImage(gd, $(Dict("format" => "svg")))
        end
        ).then(function(data)
            @var svg_data = data.replace("data:image/svg+xml,", "")
            $svg_obs[] = decodeURIComponent(svg_data)
        end
        );
    end)

    # TODO: addtraces, deletetraces, movetraces, redraw, purge, to_image,
    # download_image, extendtraces, prependtraces

    api_obs
end

# ----------------------- #
# Plotly.js api functions #
# ----------------------- #

abstract type PlotlyAPIArgs end
struct RestyleArgs <: PlotlyAPIArgs
    traces
    data
end

RestyleArgs() = RestyleArgs(nothing, Dict())

function PlotlyBase.restyle!(
        plt::WebIOPlot, ind::Union{Int,AbstractVector{Int}},
        update::Associative=Dict();
        kwargs...)
    args = RestyleArgs(ind-1, merge(update, PlotlyBase.prep_kwargs(kwargs)))
    plt.api_obs["restyle"][] = args
end

function PlotlyBase.restyle!(plt::WebIOPlot, update::Associative=Dict(); kwargs...)
    restyle!(plt, 1:length(plt.p.data), update; kwargs...)
end

struct RelayoutArgs <: PlotlyAPIArgs
    data
end

RelayoutArgs() = RelayoutArgs(Dict())
function PlotlyBase.relayout!(plt::WebIOPlot, update::Associative=Dict(); kwargs...)
    args = RelayoutArgs(merge(update, PlotlyBase.prep_kwargs(kwargs)))
    plt.api_obs["relayout"][] = args
end

struct UpdateArgs <: PlotlyAPIArgs
    traces
    data
    layout
end

UpdateArgs() = UpdateArgs(nothing, Dict(), Dict())

function PlotlyBase.update!(
        plt::WebIOPlot, ind::Union{Int,AbstractVector{Int}},
        update::Associative=Dict();
        layout::Layout=Layout(),
        kwargs...)
    args = UpdateArgs(ind-1, merge(update, PlotlyBase.prep_kwargs(kwargs)), layout)
    plt.api_obs["update"][] = args
end

function PlotlyBase.update!(plt::WebIOPlot, update::Associative=Dict(); kwargs...)
    PlotlyBase.update!(plt, 1:length(plt.p.data), update; kwargs...)
end
