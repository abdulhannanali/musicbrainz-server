%# vi: set ts=2 sw=2 ft=mason :
<%perl>

while (my ($k, $v) = each %ARGS)
{
	defined($v) or next;
	$k = html_escape($k);
	my @v = (ref($v) ? @$v : $v);
	$m->out(qq[<input type="hidden" name="$k" value="].html_escape($_).qq[">])
		for @v;
}

return;

</%perl>