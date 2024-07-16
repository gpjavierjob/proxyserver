document.getElementById("name").addEventListener('change', function () {
    console.log("Hey!!")
    var name = document.getElementById("name").value;
    document.getElementById("hostname").value = 'vpn.' + name + '.com';
    document.getElementById("namespace").value = name;
})