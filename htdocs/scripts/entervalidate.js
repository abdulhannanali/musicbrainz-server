
function validate(f)
{
    for (var i = 0; i < f.length; i++)
    {
        var e = f.elements[i];
        if (e.type != "text")
            continue;

        if ((e.className || "").match(/textfield/i) &&
        	e.value == "")
        {
            alert("Please enter all the information for this CD.");
            return false;
        }
    }

    return true;
}

