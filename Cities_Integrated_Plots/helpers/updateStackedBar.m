function updateStackedBar(ax, bars, y, labelFormat)
    delete(findall(ax,'Type','text','Tag','BarLabel'));

    n = size(y,1);
    for k = 1:n
        bars(k).YData = y(k,:)';
    end

    ymax = max(sum(y,1));
    ylim(ax,[0 ceil(ymax*1.10)]);

    for k = 1:n
        vals = bars(k).YData;
        for x = 1:numel(vals)
            if vals(x) > 0
                cum = sum(cellfun(@(bb) bb.YData(x), num2cell(bars(1:k-1))));
                yc = cum + vals(x)/2;
                text(ax,x,yc,sprintf(labelFormat,vals(x)), ...
                    'HorizontalAlignment','center','VerticalAlignment','middle', ...
                    'Color','w','BackgroundColor','k','Margin',1, ...
                    'FontWeight','bold','Tag','BarLabel');
            end
        end
    end
end
