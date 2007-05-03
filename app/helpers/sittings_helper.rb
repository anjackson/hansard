module SittingsHelper

        def turns_sparkline_tag(sitting)
                %Q[<img src="/sittings/show/#{sitting.Id}/turns_sparkline.png" class="sparkline" alt="Turns Sparkline" />]
        end

        def turns_graph_tag(sitting)
                %Q[<img src="/sittings/show/#{sitting.Id}/turns_graph.png" class="sparkline" alt="Turns Graph" />]
        end

end
