photoBoothApp.controller('PictureSetCtrl', [
  '$scope',
  '$http',
  '$uibModal',
  '$log',
  '$routeParams',
  function ($scope, $http, $uibModal, $log, $routeParams) {

    $scope.pictureSetId = $routeParams.pictureSetId;


    $scope.destroy = function () {
      $http({
        method: 'DELETE',
        url: '/picture_sets/'
      }).then(function successCallback(response) {

      }, function errorCallback(response) {

      });
    };

  }]);

